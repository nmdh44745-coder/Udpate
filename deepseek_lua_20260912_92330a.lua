-- ============================================
--  FLAIR #1 - Walk Speed + Auto Walk + AFK Farm
--  Keys: Delta2026 (24h trial) | Pass2026 (permanent)
-- ============================================

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local CoreGui           = game:GetService("CoreGui")
local HttpService       = game:GetService("HttpService")

local LP     = Players.LocalPlayer
local PGui   = LP:WaitForChild("PlayerGui")

local KEY_TRIAL = "Delta2026"
local KEY_PERM  = "Pass2026"
local DISCORD_LINK = "https://discord.gg/k65z4FxEb2"
local CONFIG_FILE  = "Flair1_Config.json"
local TRIAL_DURATION = 24 * 60 * 60

-- ============================================
--  CONFIG
-- ============================================
local Config = {
    keyType       = nil,
    trialStart    = 0,
    walkSpeed     = 60,
}

local function nowUnix() return os.time() end

local function loadConfig()
    pcall(function()
        if isfile and isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if type(data) == "table" then
                if data.keyType == "trial" or data.keyType == "perm" then
                    Config.keyType = data.keyType
                end
                if type(data.trialStart) == "number" then
                    Config.trialStart = data.trialStart
                end
                if type(data.walkSpeed) == "number" then
                    Config.walkSpeed = data.walkSpeed
                end
            end
        end
    end)
end

local function saveConfig()
    pcall(function()
        if writefile then
            writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
        end
    end)
end

loadConfig()

local function isTrialExpired()
    if Config.keyType ~= "trial" then return false end
    if Config.trialStart <= 0 then return true end
    return (nowUnix() - Config.trialStart) >= TRIAL_DURATION
end

local function getTrialRemaining()
    if Config.keyType ~= "trial" then return 0 end
    local elapsed = nowUnix() - Config.trialStart
    local remaining = TRIAL_DURATION - elapsed
    if remaining < 0 then remaining = 0 end
    return remaining
end

local function formatTime(seconds)
    if seconds <= 0 then return "0s" end
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02dh %02dm %02ds", h, m, s)
end

-- ============================================
--  CLEANUP
-- ============================================
pcall(function()
    for _, n in ipairs({"FlairKey", "FlairLoading", "FlairHub"}) do
        local o1 = CoreGui:FindFirstChild(n); if o1 then o1:Destroy() end
        local o2 = PGui:FindFirstChild(n);   if o2 then o2:Destroy() end
    end
end)

-- ============================================
--  HELPERS
-- ============================================
local function newGui(name, order)
    local g = Instance.new("ScreenGui")
    g.Name = name
    g.ResetOnSpawn = false
    g.IgnoreGuiInset = true
    g.DisplayOrder = order or 10
    g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() if syn and syn.protect_gui then syn.protect_gui(g) end end)
    if not pcall(function() g.Parent = CoreGui end) then g.Parent = PGui end
    return g
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 10)
    c.Parent = parent
    return c
end

local function stroke(parent, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col or Color3.fromRGB(60, 60, 70)
    s.Thickness = th or 1
    s.Parent = parent
    return s
end

-- ============================================
--  DISCORD TAG
-- ============================================
local function createHeadDiscordTag(character)
    if not character then return end
    local head = character:FindFirstChild("Head") or character:WaitForChild("Head", 5)
    if not head then return end

    local old = head:FindFirstChild("FlairDiscordTag")
    if old then old:Destroy() end

    local bb = Instance.new("BillboardGui")
    bb.Name = "FlairDiscordTag"
    bb.Size = UDim2.new(0, 300, 0, 50)
    bb.StudsOffset = Vector3.new(0, 3.2, 0)
    bb.AlwaysOnTop = true
    bb.MaxDistance = 500
    bb.Parent = head

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = DISCORD_LINK
    lbl.TextColor3 = Color3.fromRGB(180, 200, 255)
    lbl.Font = Enum.Font.GothamBlack
    lbl.TextSize = 18
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lbl.Parent = bb

    task.spawn(function()
        local t = 0
        while bb and bb.Parent do
            t = t + 0.05
            local pulse = 0.85 + math.abs(math.sin(t)) * 0.15
            lbl.TextTransparency = 1 - pulse
            local scale = 1 + math.sin(t * 1.5) * 0.05
            lbl.TextSize = 18 * scale
            task.wait(0.05)
        end
    end)
end

if LP.Character then
    task.spawn(function()
        task.wait(0.5)
        createHeadDiscordTag(LP.Character)
    end)
end

LP.CharacterAdded:Connect(function(char)
    task.wait(0.6)
    createHeadDiscordTag(char)
end)

-- ============================================
--  WAYPOINTS + STATE
-- ============================================
local AUTO_WALK_P1 = Vector3.new(122, 1, -98)
local AUTO_WALK_P2 = Vector3.new(125, 1, -2187)

local walkSpeed        = Config.walkSpeed
local autoWalkEnabled  = false
local autoWalkConn     = nil
local autoWalkPhase    = 1
local afkFarmEnabled   = false
local afkFarmConn      = nil
local afkFarmPhase     = 1

-- ============================================
--  WALK SPEED
-- ============================================
local function applyWalkSpeed()
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = walkSpeed end
end

task.spawn(function()
    while true do
        task.wait(0.5)
        applyWalkSpeed()
    end
end)

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyWalkSpeed()
end)

-- ============================================
--  MOVEMENT HELPERS
-- ============================================
local function isRagdollState(hum)
    if not hum then return true end
    local st = hum:GetState()
    return hum.PlatformStand
        or st == Enum.HumanoidStateType.Physics
        or st == Enum.HumanoidStateType.Ragdoll
        or st == Enum.HumanoidStateType.FallingDown
end

local function moveToPoint(targetVec)
    local char = LP.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return false end
    if isRagdollState(hum) then
        hum:Move(Vector3.zero, false)
        return false
    end

    local target = Vector3.new(targetVec.X, hrp.Position.Y, targetVec.Z)
    local offset = target - hrp.Position
    local dist = offset.Magnitude

    if dist < 3 then
        hum:Move(Vector3.zero, false)
        hrp.Velocity = Vector3.new(0, hrp.Velocity.Y, 0)
        return true
    end

    local dir = Vector3.new(offset.X, 0, offset.Z).Unit
    local spd = walkSpeed
    hum:Move(dir, false)
    hrp.Velocity = Vector3.new(dir.X * spd, hrp.Velocity.Y, dir.Z * spd)
    return false
end

-- ============================================
--  AUTO WALK
-- ============================================
local function stopAutoWalk()
    if autoWalkConn then autoWalkConn:Disconnect(); autoWalkConn = nil end
    autoWalkPhase = 1
    local char = LP.Character
    if char then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then h:Move(Vector3.zero, false) end
    end
end

local function startAutoWalk()
    if autoWalkConn then autoWalkConn:Disconnect() end
    autoWalkPhase = 1

    autoWalkConn = RunService.Heartbeat:Connect(function()
        if not autoWalkEnabled then return end

        if autoWalkPhase == 1 then
            local arrived = moveToPoint(AUTO_WALK_P1)
            if arrived then autoWalkPhase = 2 end
        elseif autoWalkPhase == 2 then
            local arrived = moveToPoint(AUTO_WALK_P2)
            if arrived then
                autoWalkEnabled = false
                if autoWalkConn then autoWalkConn:Disconnect(); autoWalkConn = nil end
                autoWalkPhase = 1
                if _autoWalkSetter then _autoWalkSetter(false) end
            end
        end
    end)
end

-- ============================================
--  AFK FARM
-- ============================================
local function stopAfkFarm()
    if afkFarmConn then afkFarmConn:Disconnect(); afkFarmConn = nil end
    afkFarmPhase = 1
    local char = LP.Character
    if char then
        local h = char:FindFirstChildOfClass("Humanoid")
        if h then h:Move(Vector3.zero, false) end
    end
end

local function startAfkFarm()
    if afkFarmConn then afkFarmConn:Disconnect() end
    afkFarmPhase = 1

    afkFarmConn = RunService.Heartbeat:Connect(function()
        if not afkFarmEnabled then return end

        if afkFarmPhase == 1 then
            local arrived = moveToPoint(AUTO_WALK_P1)
            if arrived then afkFarmPhase = 2 end
        elseif afkFarmPhase == 2 then
            local arrived = moveToPoint(AUTO_WALK_P2)
            if arrived then afkFarmPhase = 1 end
        end
    end)
end

-- ============================================
--  KEY GUI
-- ============================================
local keyGui = newGui("FlairKey", 50)

local keyFrame = Instance.new("Frame")
keyFrame.Size = UDim2.new(0, 360, 0, 240)
keyFrame.Position = UDim2.new(0.5, -180, 0.5, -120)
keyFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
keyFrame.BorderSizePixel = 0
keyFrame.Active = true
keyFrame.Parent = keyGui
corner(keyFrame, 14)
local kStroke = stroke(keyFrame, Color3.fromRGB(255, 70, 70), 1.5)
kStroke.Transparency = 0.25

local kTitle = Instance.new("TextLabel")
kTitle.Size = UDim2.new(1, 0, 0, 40)
kTitle.Position = UDim2.new(0, 0, 0, 18)
kTitle.BackgroundTransparency = 1
kTitle.Text = "🔑 Flair #1"
kTitle.TextColor3 = Color3.fromRGB(255, 70, 70)
kTitle.Font = Enum.Font.GothamBlack
kTitle.TextSize = 22
kTitle.Parent = keyFrame

local kSub = Instance.new("TextLabel")
kSub.Size = UDim2.new(1, 0, 0, 18)
kSub.Position = UDim2.new(0, 0, 0, 56)
kSub.BackgroundTransparency = 1
kSub.Text = "Enter key to continue"
kSub.TextColor3 = Color3.fromRGB(160, 160, 170)
kSub.Font = Enum.Font.Gotham
kSub.TextSize = 13
kSub.Parent = keyFrame

local kTrialInfo = Instance.new("TextLabel")
kTrialInfo.Size = UDim2.new(1, -20, 0, 32)
kTrialInfo.Position = UDim2.new(0, 10, 0, 80)
kTrialInfo.BackgroundColor3 = Color3.fromRGB(40, 20, 20)
kTrialInfo.BackgroundTransparency = 0.3
kTrialInfo.BorderSizePixel = 0
kTrialInfo.Text = "24 hour trial ended"
kTrialInfo.TextColor3 = Color3.fromRGB(255, 100, 100)
kTrialInfo.Font = Enum.Font.GothamBold
kTrialInfo.TextSize = 12
kTrialInfo.TextWrapped = true
kTrialInfo.Visible = false
kTrialInfo.Parent = keyFrame
corner(kTrialInfo, 6)

local kBox = Instance.new("TextBox")
kBox.Size = UDim2.new(0.82, 0, 0, 42)
kBox.Position = UDim2.new(0.09, 0, 0, 124)
kBox.BackgroundColor3 = Color3.fromRGB(38, 38, 46)
kBox.BorderSizePixel = 0
kBox.PlaceholderText = "Enter password..."
kBox.Text = ""
kBox.ClearTextOnFocus = false
kBox.TextColor3 = Color3.fromRGB(255, 255, 255)
kBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
kBox.Font = Enum.Font.Gotham
kBox.TextSize = 15
kBox.Parent = keyFrame
corner(kBox, 8)

local kBtn = Instance.new("TextButton")
kBtn.Size = UDim2.new(0.82, 0, 0, 42)
kBtn.Position = UDim2.new(0.09, 0, 0, 176)
kBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
kBtn.BorderSizePixel = 0
kBtn.Text = "Submit"
kBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
kBtn.Font = Enum.Font.GothamBold
kBtn.TextSize = 15
kBtn.Parent = keyFrame
corner(kBtn, 8)

makeDraggable(keyFrame, keyFrame)

-- ============================================
--  LOADING GUI
-- ============================================
local loadGui = newGui("FlairLoading", 60)

local loadFrame = Instance.new("Frame")
loadFrame.Size = UDim2.new(0, 320, 0, 160)
loadFrame.Position = UDim2.new(0.5, -160, 0.5, -80)
loadFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
loadFrame.BorderSizePixel = 0
loadFrame.Visible = false
loadFrame.Active = true
loadFrame.Parent = loadGui
corner(loadFrame, 14)
stroke(loadFrame, Color3.fromRGB(255, 70, 70), 1.5).Transparency = 0.25

local loadLbl = Instance.new("TextLabel")
loadLbl.Size = UDim2.new(1, 0, 0, 30)
loadLbl.Position = UDim2.new(0, 0, 0, 26)
loadLbl.BackgroundTransparency = 1
loadLbl.Text = "Loading Flair #1..."
loadLbl.TextColor3 = Color3.fromRGB(255, 70, 70)
loadLbl.Font = Enum.Font.GothamBlack
loadLbl.TextSize = 18
loadLbl.Parent = loadFrame

local loadPct = Instance.new("TextLabel")
loadPct.Size = UDim2.new(1, 0, 0, 20)
loadPct.Position = UDim2.new(0, 0, 0, 58)
loadPct.BackgroundTransparency = 1
loadPct.Text = "0%"
loadPct.TextColor3 = Color3.fromRGB(200, 200, 210)
loadPct.Font = Enum.Font.GothamBold
loadPct.TextSize = 14
loadPct.Parent = loadFrame

local loadBarBg = Instance.new("Frame")
loadBarBg.Size = UDim2.new(0.82, 0, 0, 10)
loadBarBg.Position = UDim2.new(0.09, 0, 0, 92)
loadBarBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
loadBarBg.BorderSizePixel = 0
loadBarBg.Parent = loadFrame
corner(loadBarBg, 5)

local loadFill = Instance.new("Frame")
loadFill.Size = UDim2.new(0, 0, 1, 0)
loadFill.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
loadFill.BorderSizePixel = 0
loadFill.Parent = loadBarBg
corner(loadFill, 5)

local loadStatus = Instance.new("TextLabel")
loadStatus.Size = UDim2.new(1, 0, 0, 18)
loadStatus.Position = UDim2.new(0, 0, 0, 115)
loadStatus.BackgroundTransparency = 1
loadStatus.Text = "Authenticating..."
loadStatus.TextColor3 = Color3.fromRGB(130, 130, 140)
loadStatus.Font = Enum.Font.Gotham
loadStatus.TextSize = 11
loadStatus.Parent = loadFrame

makeDraggable(loadFrame, loadFrame)

-- ============================================
--  MAIN GUI (with trial time at bottom)
-- ============================================
local mainGui = newGui("FlairHub", 70)

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 360, 0, 400)
main.Position = UDim2.new(0.5, -180, 0.5, -200)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
main.BorderSizePixel = 0
main.Active = true
main.Visible = false
main.Parent = mainGui
corner(main, 14)
local mStroke = stroke(main, Color3.fromRGB(255, 70, 70), 1.5)
mStroke.Transparency = 0.25

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 46)
header.BackgroundTransparency = 1
header.Parent = main

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -70, 1, 0)
title.Position = UDim2.new(0, 16, 0, 0)
title.BackgroundTransparency = 1
title.Text = "Flair #1"
title.TextColor3 = Color3.fromRGB(255, 70, 70)
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -40, 0.5, -15)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 20
closeBtn.Parent = header
corner(closeBtn, 8)

makeDraggable(main, header)

local div = Instance.new("Frame")
div.Size = UDim2.new(1, -20, 0, 1)
div.Position = UDim2.new(0, 10, 0, 46)
div.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
div.BorderSizePixel = 0
div.Parent = main

-- ============================================
--  TRIAL TIME BAR AT BOTTOM
-- ============================================
local trialBarHeight = 46
local trialBar = Instance.new("Frame")
trialBar.Size = UDim2.new(1, -20, 0, trialBarHeight)
trialBar.Position = UDim2.new(0, 10, 1, -trialBarHeight - 10)
trialBar.BackgroundColor3 = Color3.fromRGB(30, 25, 20)
trialBar.BackgroundTransparency = 0.2
trialBar.BorderSizePixel = 0
trialBar.Visible = (Config.keyType == "trial")
trialBar.Parent = main
corner(trialBar, 10)
stroke(trialBar, Color3.fromRGB(255, 180, 60), 1.2)

local trialBarDivider = Instance.new("Frame")
trialBarDivider.Size = UDim2.new(1, -20, 0, 1)
trialBarDivider.Position = UDim2.new(0, 10, 1, -trialBarHeight - 14)
trialBarDivider.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
trialBarDivider.BorderSizePixel = 0
trialBarDivider.Visible = (Config.keyType == "trial")
trialBarDivider.Parent = main

local trialLbl = Instance.new("TextLabel")
trialLbl.Size = UDim2.new(1, -20, 1, 0)
trialLbl.Position = UDim2.new(0, 10, 0, 0)
trialLbl.BackgroundTransparency = 1
trialLbl.Text = "⏳ Trial: --:--:--"
trialLbl.TextColor3 = Color3.fromRGB(255, 200, 100)
trialLbl.Font = Enum.Font.GothamBold
trialLbl.TextSize = 14
trialLbl.TextXAlignment = Enum.TextXAlignment.Left
trialLbl.TextYAlignment = Enum.TextYAlignment.Center
trialLbl.Parent = trialBar

-- Live update for trial bar
if Config.keyType == "trial" then
    task.spawn(function()
        while trialBar and trialBar.Parent do
            local rem = getTrialRemaining()
            if rem <= 0 then
                trialLbl.Text = "⏳ Trial: EXPIRED"
                trialLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
                break
            end
            trialLbl.Text = "⏳ Trial: " .. formatTime(rem) .. " remaining"
            task.wait(1)
        end
    end)
end

-- ============================================
--  CONTENT (scrollable, leaves room for trial bar)
-- ============================================
local content = Instance.new("ScrollingFrame")
content.Size = UDim2.new(1, -20, 1, -56 - trialBarHeight - 14)
content.Position = UDim2.new(0, 10, 0, 52)
content.BackgroundTransparency = 1
content.BorderSizePixel = 0
content.ScrollBarThickness = 4
content.ScrollBarImageColor3 = Color3.fromRGB(255, 70, 70)
content.CanvasSize = UDim2.new(0, 0, 0, 0)
content.AutomaticCanvasSize = Enum.AutomaticSize.Y
content.Parent = main

local uiLay = Instance.new("UIListLayout")
uiLay.SortOrder = Enum.SortOrder.LayoutOrder
uiLay.Padding = UDim.new(0, 8)
uiLay.Parent = content

local pad = Instance.new("UIPadding")
pad.PaddingBottom = UDim.new(0, 8)
pad.Parent = content

-- ============================================
--  WALK SPEED row
-- ============================================
do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 50)
    row.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    row.BorderSizePixel = 0
    row.LayoutOrder = 1
    row.Parent = content
    corner(row, 10)
    stroke(row, Color3.fromRGB(55, 55, 65), 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Walk Speed"
    lbl.TextColor3 = Color3.fromRGB(230, 230, 235)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local minusBtn = Instance.new("TextButton")
    minusBtn.Size = UDim2.new(0, 26, 0, 26)
    minusBtn.Position = UDim2.new(1, -132, 0.5, -13)
    minusBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    minusBtn.BorderSizePixel = 0
    minusBtn.Text = "−"
    minusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minusBtn.Font = Enum.Font.GothamBold
    minusBtn.TextSize = 16
    minusBtn.AutoButtonColor = false
    minusBtn.Parent = row
    corner(minusBtn, 6)

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 60, 0, 26)
    box.Position = UDim2.new(1, -100, 0.5, -13)
    box.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    box.BorderSizePixel = 0
    box.Text = tostring(walkSpeed)
    box.TextColor3 = Color3.fromRGB(255, 255, 255)
    box.Font = Enum.Font.GothamBold
    box.TextSize = 13
    box.TextXAlignment = Enum.TextXAlignment.Center
    box.Parent = row
    corner(box, 6)

    local plusBtn = Instance.new("TextButton")
    plusBtn.Size = UDim2.new(0, 26, 0, 26)
    plusBtn.Position = UDim2.new(1, -34, 0.5, -13)
    plusBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
    plusBtn.BorderSizePixel = 0
    plusBtn.Text = "+"
    plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    plusBtn.Font = Enum.Font.GothamBold
    plusBtn.TextSize = 16
    plusBtn.AutoButtonColor = false
    plusBtn.Parent = row
    corner(plusBtn, 6)

    local function apply(v)
        v = math.clamp(v, 30, 250)
        walkSpeed = v
        Config.walkSpeed = v
        box.Text = tostring(v)
        applyWalkSpeed()
        saveConfig()
    end

    box.FocusLost:Connect(function()
        local n = tonumber(box.Text)
        if n then apply(n) else box.Text = tostring(walkSpeed) end
    end)

    minusBtn.MouseButton1Click:Connect(function()
        local n = tonumber(box.Text) or walkSpeed
        apply(n - 5)
    end)

    plusBtn.MouseButton1Click:Connect(function()
        local n = tonumber(box.Text) or walkSpeed
        apply(n + 5)
    end)
end

-- ============================================
--  AUTO WALK toggle
-- ============================================
local _autoWalkSetter
do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 50)
    row.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    row.BorderSizePixel = 0
    row.LayoutOrder = 2
    row.Parent = content
    corner(row, 10)
    stroke(row, Color3.fromRGB(55, 55, 65), 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Auto Walk"
    lbl.TextColor3 = Color3.fromRGB(230, 230, 235)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 44, 0, 22)
    track.Position = UDim2.new(1, -58, 0.5, -11)
    track.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
    track.BorderSizePixel = 0
    track.Parent = row
    corner(track, 11)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, 8)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    local isOn = false
    local function setter(v)
        isOn = v
        TweenService:Create(track, TweenInfo.new(0.15), {
            BackgroundColor3 = isOn and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(50, 50, 58)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = isOn and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
    end
    _autoWalkSetter = setter

    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        setter(isOn)
        autoWalkEnabled = isOn
        if isOn then
            if afkFarmEnabled then
                afkFarmEnabled = false
                stopAfkFarm()
                if _afkFarmSetter then _afkFarmSetter(false) end
            end
            startAutoWalk()
        else
            stopAutoWalk()
        end
    end)
end

-- ============================================
--  AFK FARM toggle
-- ============================================
local _afkFarmSetter
do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 50)
    row.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    row.BorderSizePixel = 0
    row.LayoutOrder = 3
    row.Parent = content
    corner(row, 10)
    stroke(row, Color3.fromRGB(55, 55, 65), 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "AFK Farm"
    lbl.TextColor3 = Color3.fromRGB(230, 230, 235)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(0.6, 0, 0, 14)
    sub.Position = UDim2.new(0, 14, 0.5, 4)
    sub.BackgroundTransparency = 1
    sub.Text = "Loops forever"
    sub.TextColor3 = Color3.fromRGB(120, 120, 135)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 10
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 44, 0, 22)
    track.Position = UDim2.new(1, -58, 0.5, -11)
    track.BackgroundColor3 = Color3.fromRGB(50, 50, 58)
    track.BorderSizePixel = 0
    track.Parent = row
    corner(track, 11)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    knob.BorderSizePixel = 0
    knob.Parent = track
    corner(knob, 8)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = row

    local isOn = false
    local function setter(v)
        isOn = v
        TweenService:Create(track, TweenInfo.new(0.15), {
            BackgroundColor3 = isOn and Color3.fromRGB(255, 70, 70) or Color3.fromRGB(50, 50, 58)
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = isOn and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
    end
    _afkFarmSetter = setter

    btn.MouseButton1Click:Connect(function()
        isOn = not isOn
        setter(isOn)
        afkFarmEnabled = isOn
        if isOn then
            if autoWalkEnabled then
                autoWalkEnabled = false
                stopAutoWalk()
                if _autoWalkSetter then _autoWalkSetter(false) end
            end
            startAfkFarm()
        else
            stopAfkFarm()
        end
    end)
end

-- ============================================
--  LOGOUT button
-- ============================================
do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 42)
    row.BackgroundColor3 = Color3.fromRGB(28, 28, 36)
    row.BorderSizePixel = 0
    row.LayoutOrder = 4
    row.Parent = content
    corner(row, 10)
    stroke(row, Color3.fromRGB(55, 55, 65), 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Logout (Forget Key)"
    lbl.TextColor3 = Color3.fromRGB(230, 230, 235)
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 80, 0, 26)
    btn.Position = UDim2.new(1, -94, 0.5, -13)
    btn.BackgroundColor3 = Color3.fromRGB(120, 30, 40)
    btn.BorderSizePixel = 0
    btn.Text = "LOGOUT"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 11
    btn.AutoButtonColor = false
    btn.Parent = row
    corner(btn, 6)

    btn.MouseButton1Click:Connect(function()
        Config.keyType = nil
        Config.trialStart = 0
        saveConfig()
        main.Visible = false
        keyFrame.Visible = true
    end)
end

closeBtn.MouseButton1Click:Connect(function()
    main.Visible = false
end)

-- ============================================
--  LOADING BAR
-- ============================================
local function runLoadingBar()
    keyFrame.Visible = false
    loadFrame.Visible = true
    loadFill.Size = UDim2.new(0, 0, 1, 0)

    local steps = {
        {pct = 0.15, text = "Authenticating..."},
        {pct = 0.35, text = "Loading modules..."},
        {pct = 0.60, text = "Preparing waypoints..."},
        {pct = 0.85, text = "Finalizing..."},
        {pct = 1.00, text = "Ready!"},
    }

    for _, step in ipairs(steps) do
        TweenService:Create(loadFill, TweenInfo.new(0.6, Enum.EasingStyle.Quad), {
            Size = UDim2.new(step.pct, 0, 1, 0)
        }):Play()
        loadPct.Text = math.floor(step.pct * 100) .. "%"
        loadStatus.Text = step.text
        task.wait(0.6)
    end
    task.wait(0.4)
    loadFrame.Visible = false
    main.Visible = true
end

-- ============================================
--  KEY SUBMIT HANDLER
-- ============================================
kBtn.MouseButton1Click:Connect(function()
    local entered = kBox.Text

    if entered == KEY_PERM then
        Config.keyType = "perm"
        Config.trialStart = 0
        saveConfig()
        trialBar.Visible = false
        trialBarDivider.Visible = false
        runLoadingBar()

    elseif entered == KEY_TRIAL then
        local proceed = true
        local reason = ""

        if Config.keyType == "trial" and Config.trialStart > 0 then
            if isTrialExpired() then
                proceed = false
                reason = "24 hour trial ended"
            end
        end

        if proceed then
            if Config.keyType ~= "trial" or Config.trialStart <= 0 then
                Config.trialStart = nowUnix()
                Config.keyType = "trial"
                saveConfig()
            end
            trialBar.Visible = true
            trialBarDivider.Visible = true
            runLoadingBar()
        else
            kBox.Text = ""
            kBox.PlaceholderText = "❌ " .. reason
            kBox.PlaceholderColor3 = Color3.fromRGB(255, 90, 90)
            kTrialInfo.Text = reason
            kTrialInfo.Visible = true
            local startPos = keyFrame.Position
            for i = 1, 6 do
                local offset = (i % 2 == 0) and 8 or -8
                keyFrame.Position = startPos + UDim2.new(0, offset, 0, 0)
                task.wait(0.04)
            end
            keyFrame.Position = startPos
        end

    else
        kBox.Text = ""
        kBox.PlaceholderText = "❌ Wrong key — try again"
        kBox.PlaceholderColor3 = Color3.fromRGB(255, 90, 90)
        local startPos = keyFrame.Position
        for i = 1, 6 do
            local offset = (i % 2 == 0) and 8 or -8
            keyFrame.Position = startPos + UDim2.new(0, offset, 0, 0)
            task.wait(0.04)
        end
        keyFrame.Position = startPos
    end
end)

kBox.FocusLost:Connect(function(enter)
    if enter then kBtn:Activate() end
end)

-- ============================================
--  AUTO-LOAD IF VALID KEY EXISTS
-- ============================================
task.spawn(function()
    task.wait(0.3)

    if Config.keyType == "perm" then
        keyFrame.Visible = false
        trialBar.Visible = false
        trialBarDivider.Visible = false
        runLoadingBar()
        print("[Flair #1] Auto-loaded (permanent key)")

    elseif Config.keyType == "trial" and not isTrialExpired() then
        keyFrame.Visible = false
        trialBar.Visible = true
        trialBarDivider.Visible = true
        runLoadingBar()
        print("[Flair #1] Auto-loaded (trial) — " .. formatTime(getTrialRemaining()) .. " remaining")

    else
        keyFrame.Visible = true
        if Config.keyType == "trial" and isTrialExpired() then
            kTrialInfo.Text = "24 hour trial ended"
            kTrialInfo.Visible = true
        end
    end
end)

print("[Flair #1] Loaded — Trial: " .. KEY_TRIAL .. " | Perm: " .. KEY_PERM)