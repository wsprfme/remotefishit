l--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                         FISH IT AUTO FISHER                               ║
    ║                    Delta Executor • Android Ready                         ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

--// CLEANUP
if getgenv().FishIt_Running then
    getgenv().FishIt_Running = false
    task.wait(0.3)
end
pcall(function()
    for _, gui in pairs(game:GetService("CoreGui"):GetChildren()) do
        if gui.Name:find("FishIt") then gui:Destroy() end
    end
end)

--// SERVICES
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--// REMOTES
local net = RS.Packages._Index["sleitnick_net@0.2.0"].net

local R = {
    Charge = net["RF/ChargeFishingRod"],
    Request = net["RF/RequestFishingMinigameStarted"],
    Complete = net["RE/FishingCompleted"],
    Cancel = net["RF/CancelFishingInputs"],
    Sell = net["RF/SellAllItems"],
    Favorite = net["RE/FavoriteItem"],
    AutoGreat = net["RF/UpdateAutoFishingState"],
    NewFish = net["RE/ObtainedNewFishNotification"],
    Tank = net["RF/EquipOxygenTank"],
    Radar = net["RF/UpdateFishingRadar"],
    Weather = net["RF/PurchaseWeatherEvent"],
}

--// CONFIG
local Args = {-1.115296483039856, 0, 1763651451.636425}

local CFG = {
    Speed = "Fast",      -- "Fast", "Normal", "Safe"
    SellTime = 60,       -- seconds
    FavRarity = "Mythic" -- "Mythic", "Legendary", "Epic", "All"
}

local STATE = {
    Fishing = false,
    AutoSell = false,
    AutoFav = false,
    AutoWeather = false,
    WaterWalk = false,
    FPSBoost = false,
    Count = 0,
}

getgenv().FishIt_Running = true

--// SPEED PRESETS
local SPEEDS = {
    Fast = {charge = 1.10, catch = 0.50, reset = 0.15, turbo = true},
    Normal = {charge = 1.30, catch = 0.70, reset = 0.25, turbo = true},
    Safe = {charge = 1.50, catch = 1.00, reset = 0.35, turbo = false},
}

--// WAYPOINTS
local WP = {
    ["Spawn"] = Vector3.new(-33, 10, 2770),
    ["Kohana"] = Vector3.new(-626, 16, 588),
    ["Kohana Lava"] = Vector3.new(-594, 59, 112),
    ["Coral Reef"] = Vector3.new(-3138, 4, 2132),
    ["Sisyphus"] = Vector3.new(-3657, -134, -963),
    ["Treasure Room"] = Vector3.new(-3604, -284, -1632),
    ["Esoteric Island"] = Vector3.new(1991, 6, 1390),
    ["Esoteric Depths"] = Vector3.new(3240, -1302, 1404),
    ["Ancient Jungle"] = Vector3.new(1463, 8, -358),
    ["Ancient Ruin"] = Vector3.new(6067, -586, 4714),
    ["Iron Cavern"] = Vector3.new(-8798, -585, 241),
    ["Crater Island"] = Vector3.new(1070, 2, 5102),
    ["Tropical Grove"] = Vector3.new(-2132, 53, 3630),
    ["Weather Machine"] = Vector3.new(-1517, 3, 1910),
    ["Underground"] = Vector3.new(2135, -91, -700),
    ["Classic Island"] = Vector3.new(1433, 44, 2755),
    ["Pirate Cove"] = Vector3.new(3405, 10, 3350),
    ["Christmas Cave"] = Vector3.new(715, -487, 8910),
}

local WPNames = {}
for n in pairs(WP) do table.insert(WPNames, n) end
table.sort(WPNames)

--// UTILS
local function HRP()
    local c = Player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function TP(pos)
    local h = HRP()
    if h then
        h.AssemblyLinearVelocity = Vector3.zero
        h.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end

--// BLOCKER
local BLOCKED = {[R.Charge]=1, [R.Request]=1, [R.Complete]=1, [R.Cancel]=1}
if hookmetamethod and checkcaller then
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if STATE.Fishing and BLOCKED[self] and not checkcaller() then
            if m == "InvokeServer" then return task.wait(9e9) end
            if m == "FireServer" then return end
        end
        return old(self, ...)
    end)
end

--// SPAWN LIMITER
local spawns = 0
local function Light(fn)
    if spawns >= 4 then return end
    spawns += 1
    task.spawn(function() pcall(fn); spawns -= 1 end)
end

--// FISHING
local function Fish()
    local speed = SPEEDS[CFG.Speed]
    
    pcall(function() R.AutoGreat:InvokeServer(true) end)
    pcall(function() R.Cancel:InvokeServer() end)
    task.wait(0.05)
    
    while STATE.Fishing do
        if speed.turbo then
            Light(function() R.Charge:InvokeServer() end)
            task.wait(0.01)
            Light(function() R.Request:InvokeServer(unpack(Args)) end)
            task.wait(speed.charge)
        else
            pcall(function() R.Charge:InvokeServer() end)
            task.wait(0.05)
            pcall(function() R.Request:InvokeServer(unpack(Args)) end)
            task.wait(speed.catch)
        end
        
        pcall(function() R.Complete:FireServer() end)
        task.wait(speed.reset)
        pcall(function() R.Cancel:InvokeServer() end)
        task.wait(0.01)
        
        STATE.Count += 1
    end
    
    pcall(function() R.AutoGreat:InvokeServer(false) end)
end

local function StartFish()
    if STATE.Fishing then return end
    STATE.Fishing = true
    task.spawn(Fish)
end

local function StopFish()
    STATE.Fishing = false
    pcall(function() R.Complete:FireServer() end)
    pcall(function() R.Cancel:InvokeServer() end)
end

--// AUTO SELL
task.spawn(function()
    while getgenv().FishIt_Running do
        if STATE.AutoSell then
            task.wait(CFG.SellTime)
            if STATE.AutoSell then pcall(function() R.Sell:InvokeServer() end) end
        else
            task.wait(1)
        end
    end
end)

--// AUTO FAVORITE
local FishDB = {}
pcall(function()
    for _, m in ipairs(RS.Items:GetChildren()) do
        if m:IsA("ModuleScript") then
            local ok, d = pcall(require, m)
            if ok and d and d.Data and d.Data.Type == "Fish" then
                FishDB[d.Data.Id] = d.Data.Tier
            end
        end
    end
end)

local RARITY_MIN = {Mythic = 6, Legendary = 5, Epic = 4, All = 1}
local known = {}

local function CheckFav(item)
    if not item or known[item.UUID] then return end
    local tier = FishDB[item.Id]
    local minTier = RARITY_MIN[CFG.FavRarity] or 6
    if tier and tier >= minTier and not item.Favorited then
        pcall(function() R.Favorite:FireServer(item.UUID) end)
    end
    known[item.UUID] = true
end

local function ScanInv()
    pcall(function()
        local Replion = require(RS.Packages.Replion)
        local Data = Replion.Client:WaitReplion("Data")
        local inv = Data:Get("Inventory")
        if inv and inv.Items then
            for _, item in pairs(inv.Items) do CheckFav(item) end
        end
    end)
end

pcall(function()
    R.NewFish.OnClientEvent:Connect(function()
        if STATE.AutoFav then task.defer(ScanInv) end
    end)
end)

--// AUTO WEATHER
local WeatherConn = nil
local function StartWeather()
    if WeatherConn then WeatherConn:Disconnect() end
    pcall(function()
        local Replion = require(RS.Packages.Replion)
        local Events = Replion.Client:WaitReplion("Events")
        local function Check()
            if not STATE.AutoWeather then return end
            pcall(function() R.Weather:InvokeServer("Wind") end)
        end
        WeatherConn = Events:OnChange("WeatherMachine", function() task.defer(Check) end)
        Check()
    end)
end

--// WATER WALK
local WaterPart, WaterConn = nil, nil
local function StartWater()
    if WaterPart then return end
    local h = HRP()
    if not h then return end
    local waterY = h.Position.Y - 2
    WaterPart = Instance.new("Part")
    WaterPart.Size = Vector3.new(18, 1, 18)
    WaterPart.Anchored = true
    WaterPart.CanCollide = true
    WaterPart.Transparency = 1
    WaterPart.Parent = Workspace
    WaterConn = RunService.Heartbeat:Connect(function()
        local hr = HRP()
        if hr and WaterPart then
            WaterPart.CFrame = CFrame.new(hr.Position.X, waterY + 0.1, hr.Position.Z)
        end
    end)
end

local function StopWater()
    if WaterConn then WaterConn:Disconnect(); WaterConn = nil end
    if WaterPart then WaterPart:Destroy(); WaterPart = nil end
end

--// FPS BOOST
local function ToggleFPS(on)
    STATE.FPSBoost = on
    if on then
        pcall(function()
            settings().Rendering.QualityLevel = 1
            Lighting.GlobalShadows = false
            if setfpscap then setfpscap(30) end
        end)
        for _, v in pairs(game:GetDescendants()) do
            pcall(function()
                if v:IsA("BasePart") then v.Material = Enum.Material.Plastic; v.CastShadow = false end
            end)
        end
    else
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            Lighting.GlobalShadows = true
            if setfpscap then setfpscap(60) end
        end)
    end
end

--// ANTI-AFK
pcall(function()
    if getconnections then
        for _, c in pairs(getconnections(Player.Idled)) do pcall(function() c:Disable() end) end
    end
    Player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)

--// ══════════════════════════════════════════════════════════════════════════
--// UI
--// ══════════════════════════════════════════════════════════════════════════
local G = Instance.new("ScreenGui")
G.Name = "FishIt_UI"
G.ResetOnSpawn = false
pcall(function() G.Parent = CoreGui end)
if not G.Parent then G.Parent = PlayerGui end

local C = {
    bg = Color3.fromRGB(20, 22, 28),
    header = Color3.fromRGB(50, 180, 100),
    btn = Color3.fromRGB(35, 38, 48),
    btnHover = Color3.fromRGB(50, 55, 70),
    on = Color3.fromRGB(60, 180, 100),
    off = Color3.fromRGB(180, 60, 60),
    text = Color3.fromRGB(255, 255, 255),
    dim = Color3.fromRGB(150, 150, 150),
    accent = Color3.fromRGB(80, 200, 130),
}

-- Main Window
local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 300, 0, 420)
Main.Position = UDim2.new(0.5, -150, 0.5, -210)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Parent = G
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = C.header
Header.BorderSizePixel = 0
Header.Parent = Main
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🎣 Fish It Auto"
TitleLabel.TextColor3 = C.text
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

-- Fish Count (shows up to 9)
local FishCount = Instance.new("TextLabel")
FishCount.Size = UDim2.new(0, 80, 0, 24)
FishCount.Position = UDim2.new(1, -90, 0.5, -12)
FishCount.BackgroundColor3 = Color3.fromRGB(30, 100, 60)
FishCount.Text = "🐟 0"
FishCount.TextColor3 = C.text
FishCount.TextSize = 12
FishCount.Font = Enum.Font.GothamBold
FishCount.Parent = Header
Instance.new("UICorner", FishCount).CornerRadius = UDim.new(0, 6)

-- Update fish count display (show fish icons based on catches)
task.spawn(function()
    local lastCount = 0
    while getgenv().FishIt_Running do
        if STATE.Count ~= lastCount then
            lastCount = STATE.Count
            -- Show fish icons (max 9)
            local fishIcons = ""
            local displayNum = math.min(STATE.Count % 10, 9)
            if displayNum == 0 and STATE.Count > 0 then displayNum = 9 end
            for i = 1, displayNum do
                fishIcons = fishIcons .. "🐟"
            end
            FishCount.Text = fishIcons .. " " .. STATE.Count
        end
        task.wait(0.5)
    end
end)

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = C.text
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- Content Scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -16, 1, -50)
Scroll.Position = UDim2.new(0, 8, 0, 45)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 3
Scroll.CanvasSize = UDim2.new(0, 0, 0, 700)
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 6)
Layout.Parent = Scroll

Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 10)
end)

--// UI HELPERS
local function AddSection(text)
    local s = Instance.new("TextLabel")
    s.Size = UDim2.new(1, 0, 0, 22)
    s.BackgroundTransparency = 1
    s.Text = "▸ " .. text
    s.TextColor3 = C.accent
    s.TextSize = 12
    s.Font = Enum.Font.GothamBold
    s.TextXAlignment = Enum.TextXAlignment.Left
    s.Parent = Scroll
end

local function AddToggle(name, desc, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 40)
    f.BackgroundColor3 = C.btn
    f.BorderSizePixel = 0
    f.Parent = Scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.65, -8, 0, 20)
    l.Position = UDim2.new(0, 10, 0, 4)
    l.BackgroundTransparency = 1
    l.Text = name
    l.TextColor3 = C.text
    l.TextSize = 13
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    
    if desc then
        local d = Instance.new("TextLabel")
        d.Size = UDim2.new(0.65, -8, 0, 14)
        d.Position = UDim2.new(0, 10, 0, 22)
        d.BackgroundTransparency = 1
        d.Text = desc
        d.TextColor3 = C.dim
        d.TextSize = 10
        d.Font = Enum.Font.Gotham
        d.TextXAlignment = Enum.TextXAlignment.Left
        d.Parent = f
    end
    
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 55, 0, 28)
    b.Position = UDim2.new(1, -65, 0.5, -14)
    b.BackgroundColor3 = default and C.on or C.off
    b.Text = default and "ON" or "OFF"
    b.TextColor3 = C.text
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    
    local state = default
    b.MouseButton1Click:Connect(function()
        state = not state
        b.BackgroundColor3 = state and C.on or C.off
        b.Text = state and "ON" or "OFF"
        callback(state)
    end)
    
    return function(v)
        state = v
        b.BackgroundColor3 = state and C.on or C.off
        b.Text = state and "ON" or "OFF"
    end
end

local function AddButton(name, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 36)
    b.BackgroundColor3 = C.btn
    b.Text = name
    b.TextColor3 = C.text
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.Parent = Scroll
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseButton1Click:Connect(callback)
end

local function AddDropdown(name, options, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 36)
    f.BackgroundColor3 = C.btn
    f.BorderSizePixel = 0
    f.Parent = Scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.45, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = name
    l.TextColor3 = C.text
    l.TextSize = 12
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    
    local idx = 1
    for i, v in ipairs(options) do
        if v == default then idx = i break end
    end
    
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.48, -10, 0, 26)
    b.Position = UDim2.new(0.52, 0, 0.5, -13)
    b.BackgroundColor3 = C.accent
    b.Text = options[idx]
    b.TextColor3 = C.text
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    
    b.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        b.Text = options[idx]
        callback(options[idx])
    end)
end

--// ══════════════════════════════════════════════════════════════════════════
--// BUILD UI
--// ══════════════════════════════════════════════════════════════════════════

AddSection("FISHING")

AddDropdown("Speed", {"Fast", "Normal", "Safe"}, "Fast", function(v)
    CFG.Speed = v
end)

AddToggle("🎣 Start Fishing", "Tap to start/stop auto fishing", false, function(v)
    if v then StartFish() else StopFish() end
end)

AddButton("🔧 Fix Stuck", function()
    pcall(function() R.Complete:FireServer() end)
    pcall(function() R.Cancel:InvokeServer() end)
end)

AddSection("AUTO FEATURES")

AddDropdown("Sell Every", {"30s", "60s", "120s", "300s"}, "60s", function(v)
    CFG.SellTime = tonumber(v:gsub("s", ""))
end)

AddToggle("Auto Sell", "Sell otomatis tiap X detik", false, function(v)
    STATE.AutoSell = v
end)

AddDropdown("Favorite", {"Mythic", "Legendary", "Epic", "All"}, "Mythic", function(v)
    CFG.FavRarity = v
end)

AddToggle("Auto Favorite", "Tandai ikan langka otomatis", false, function(v)
    STATE.AutoFav = v
    if v then ScanInv() end
end)

AddToggle("Auto Weather", "Beli weather Wind otomatis", false, function(v)
    STATE.AutoWeather = v
    if v then StartWeather() end
end)

AddSection("TELEPORT")

local selectedWP = "Sisyphus"
AddDropdown("Location", WPNames, "Sisyphus", function(v)
    selectedWP = v
end)

AddButton("📍 Teleport ke Lokasi", function()
    if WP[selectedWP] then TP(WP[selectedWP]) end
end)

AddSection("QUICK TELEPORT")

AddButton("⭐ Sisyphus", function() TP(WP["Sisyphus"]) end)
AddButton("🌊 Esoteric Depths", function() TP(WP["Esoteric Depths"]) end)
AddButton("💎 Treasure Room", function() TP(WP["Treasure Room"]) end)
AddButton("🏴‍☠️ Pirate Cove", function() TP(WP["Pirate Cove"]) end)

AddSection("BOOST & TOOLS")

AddToggle("FPS Boost", "Grafik rendah, performa tinggi", false, function(v)
    ToggleFPS(v)
end)

AddToggle("Water Walk", "Jalan di atas air", false, function(v)
    STATE.WaterWalk = v
    if v then StartWater() else StopWater() end
end)

AddButton("🤿 Equip Diving Gear", function()
    pcall(function() R.Tank:InvokeServer(105) end)
end)

AddButton("💰 Sell Now", function()
    pcall(function() R.Sell:InvokeServer() end)
end)

--// ══════════════════════════════════════════════════════════════════════════
--// DRAGGABLE
--// ══════════════════════════════════════════════════════════════════════════
local dragging, dragStart, startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

Header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                     input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

--// ══════════════════════════════════════════════════════════════════════════
--// TOGGLE BUTTON
--// ══════════════════════════════════════════════════════════════════════════
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0, 10, 0.5, -25)
ToggleBtn.BackgroundColor3 = C.header
ToggleBtn.Text = "🎣"
ToggleBtn.TextSize = 24
ToggleBtn.Parent = G
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(1, 0)

ToggleBtn.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
end)

-- Draggable toggle button
local btnDrag, btnStart, btnPos

ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        btnDrag = true
        btnStart = input.Position
        btnPos = ToggleBtn.Position
    end
end)

ToggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        btnDrag = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if btnDrag and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - btnStart
        ToggleBtn.Position = UDim2.new(
            btnPos.X.Scale, btnPos.X.Offset + delta.X,
            btnPos.Y.Scale, btnPos.Y.Offset + delta.Y
        )
    end
end)

--// DONE
print([[
╔═════════════════════════════════════════════╗
║      FISH IT AUTO - LOADED!                 ║
║      Tap 🎣 to open menu                    ║
╚═════════════════════════════════════════════╝
]])
