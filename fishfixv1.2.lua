l--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                    FISH IT - ULTRA EDITION                                ║
    ║               Sidebar UI • Delta Compatible • Android                     ║
    ╠═══════════════════════════════════════════════════════════════════════════╣
    ║  Features:                                                                ║
    ║  ✅ Ultra-Turbo Fishing (3+ ikan cepat)     ✅ Auto Jual                  ║
    ║  ✅ Auto Favorite                           ✅ 21 Lokasi Teleport         ║
    ║  ✅ Auto Cuaca                              ✅ Auto Event                  ║
    ║  ✅ Jalan di Air                            ✅ Anti Lag                    ║
    ║  ✅ Sidebar + Tabs UI                       ✅ Input Number               ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 1: CLEANUP
--// ══════════════════════════════════════════════════════════════════════════
if getgenv().FishIt_Running then
    getgenv().FishIt_Running = false
    task.wait(0.3)
end

pcall(function()
    for _, gui in pairs(game:GetService("CoreGui"):GetChildren()) do
        if gui.Name:find("FishIt") then gui:Destroy() end
    end
end)

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 2: SERVICES
--// ══════════════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 3: REMOTES
--// ══════════════════════════════════════════════════════════════════════════
local net = RS.Packages._Index["sleitnick_net@0.2.0"].net

local R = {
    Charge = net["RF/ChargeFishingRod"],
    Request = net["RF/RequestFishingMinigameStarted"],
    Complete = net["RE/FishingCompleted"],
    Cancel = net["RF/CancelFishingInputs"],
    Sell = net["RF/SellAllItems"],
    Equip = net["RE/EquipToolFromHotbar"],
    Unequip = net["RE/UnequipToolFromHotbar"],
    Favorite = net["RE/FavoriteItem"],
    AutoGreat = net["RF/UpdateAutoFishingState"],
    NewFish = net["RE/ObtainedNewFishNotification"],
    Tank = net["RF/EquipOxygenTank"],
    Radar = net["RF/UpdateFishingRadar"],
    Weather = net["RF/PurchaseWeatherEvent"],
}

print("[FishIt] Remotes loaded")

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 4: CONFIG & STATE
--// ══════════════════════════════════════════════════════════════════════════
local Args = {-1.115296483039856, 0, 1763651451.636425}

local CFG = {
    ChargeDelay = 0.9,   -- Optimized for ultra-turbo
    CatchDelay = 0.4,    -- Faster catch
    ResetDelay = 0.1,    -- Minimal reset
    SellInterval = 60,
    FavRarities = {[6]=true, [7]=true}, -- Mythic, Secret
    WeatherTargets = {},
    -- BLATANT MODE: Ultra-fast settings
    CompleteDelay = 0.01,  -- Delay setelah Complete
    CancelDelay = 0.01,    -- Delay setelah Cancel
}

local STATE = {
    Fishing = false,
    Turbo = true,
    Blatant = false,    -- BLATANT MODE: Flash speed!
    AutoGreat = true,
    AutoSell = false,
    AutoFav = false,
    AutoWeather = false,
    AutoEvent = false,
    WaterWalk = false,
    FPSBoost = false,
    No3D = false,
    ShowHUD = false,
    Count = 0,
}

getgenv().FishIt_Running = true
getgenv().FishIt_State = STATE

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 5: WAYPOINTS (21 LOCATIONS - No Iron Cafe, Mount Hallow + Pirate Cove)
--// ══════════════════════════════════════════════════════════════════════════
local WP = {
    ["Fisherman Island"] = Vector3.new(-33, 10, 2770),
    ["Traveling Merchant"] = Vector3.new(-135, 2, 2764),
    ["Kohana"] = Vector3.new(-626, 16, 588),
    ["Kohana Lava"] = Vector3.new(-594, 59, 112),
    ["Esoteric Island"] = Vector3.new(1991, 6, 1390),
    ["Esoteric Depths"] = Vector3.new(3240, -1302, 1404),
    ["Tropical Grove"] = Vector3.new(-2132, 53, 3630),
    ["Coral Reef"] = Vector3.new(-3138, 4, 2132),
    ["Weather Machine"] = Vector3.new(-1517, 3, 1910),
    ["Sisyphus Statue"] = Vector3.new(-3657, -134, -963),
    ["Treasure Room"] = Vector3.new(-3604, -284, -1632),
    ["Ancient Jungle"] = Vector3.new(1463, 8, -358),
    ["Ancient Ruin"] = Vector3.new(6067, -586, 4714),
    ["Sacred Temple"] = Vector3.new(1476, -22, -632),
    ["Classic Island"] = Vector3.new(1433, 44, 2755),
    ["Iron Cavern"] = Vector3.new(-8798, -585, 241),
    ["Crater Island"] = Vector3.new(1070, 2, 5102),
    ["Christmas Island"] = Vector3.new(1175, 24, 1558),
    ["Underground Cellar"] = Vector3.new(2135, -91, -700),
    ["Christmas Cave"] = Vector3.new(715, -487, 8910),
    ["Pirate Cove"] = Vector3.new(3405, 10, 3350),
}

local WPNames = {}
for n in pairs(WP) do table.insert(WPNames, n) end
table.sort(WPNames)

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 6: UTILITIES
--// ══════════════════════════════════════════════════════════════════════════
local function HRP()
    local c = Player.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function TP(pos)
    local h = HRP()
    if h then
        h.AssemblyLinearVelocity = Vector3.zero
        h.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        return true
    end
    return false
end

local function SafeTP(pos)
    for _ = 1, 5 do
        local h = HRP()
        if h then
            h.AssemblyLinearVelocity = Vector3.zero
            h.CFrame = CFrame.new(pos)
        end
        task.wait(0.08)
    end
end

local function GetPlayers()
    local list = {}
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player then
            table.insert(list, p.Name)
        end
    end
    table.sort(list)
    return list
end

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 7: FISHING BLOCKER
--// ══════════════════════════════════════════════════════════════════════════
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
    print("[FishIt] Blocker installed")
end

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 8: SPAWN LIMITER (For Ultra-Turbo)
--// ══════════════════════════════════════════════════════════════════════════
local spawns = 0
local function Light(fn)
    if spawns >= 6 then return end  -- Increased for ultra-turbo
    spawns += 1
    task.spawn(function() pcall(fn); spawns -= 1 end)
end

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 9: FISHING LOGIC (Normal, Turbo, Blatant)
--// ══════════════════════════════════════════════════════════════════════════
local function Fish()
    if STATE.AutoGreat then pcall(function() R.AutoGreat:InvokeServer(true) end) end
    pcall(function() R.Cancel:InvokeServer() end)
    task.wait(0.02)
    
    while STATE.Fishing do
        if STATE.Blatant then
            -- ⚡ BLATANT MODE: FLASH SPEED! Minimal delays
            Light(function() R.Charge:InvokeServer() end)
            Light(function() R.Request:InvokeServer(unpack(Args)) end)
            task.wait(0.01)  -- Tiny wait for server
            
            pcall(function() R.Complete:FireServer() end)
            task.wait(CFG.CompleteDelay)
            pcall(function() R.Cancel:InvokeServer() end)
            task.wait(CFG.CancelDelay)
            
        elseif STATE.Turbo then
            -- TURBO: Parallel calls + optimized delays
            Light(function() R.Charge:InvokeServer() end)
            task.wait(0.005)
            Light(function() R.Request:InvokeServer(unpack(Args)) end)
            task.wait(CFG.ChargeDelay)
            
            pcall(function() R.Complete:FireServer() end)
            task.wait(CFG.ResetDelay)
            pcall(function() R.Cancel:InvokeServer() end)
            task.wait(0.005)
        else
            -- NORMAL: Standard fishing
            pcall(function() R.Charge:InvokeServer() end)
            task.wait(0.05)
            pcall(function() R.Request:InvokeServer(unpack(Args)) end)
            task.wait(CFG.CatchDelay)
            
            pcall(function() R.Complete:FireServer() end)
            task.wait(CFG.ResetDelay)
            pcall(function() R.Cancel:InvokeServer() end)
            task.wait(0.01)
        end
        
        STATE.Count += 1
    end
    
    if STATE.AutoGreat then pcall(function() R.AutoGreat:InvokeServer(false) end) end
end

local function StartFish()
    if STATE.Fishing then return end
    STATE.Fishing = true
    task.spawn(Fish)
    local mode = STATE.Blatant and "(BLATANT ⚡)" or (STATE.Turbo and "(TURBO)" or "(Normal)")
    print("[FishIt] Mancing dimulai", mode)
end

local function StopFish()
    STATE.Fishing = false
    pcall(function() R.Complete:FireServer() end)
    pcall(function() R.Cancel:InvokeServer() end)
    print("[FishIt] Mancing berhenti. Total:", STATE.Count)
end

local function Unstuck()
    pcall(function() R.Complete:FireServer() end)
    pcall(function() R.Cancel:InvokeServer() end)
    print("[FishIt] Reset stuck")
end

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 10: AUTO SELL
--// ══════════════════════════════════════════════════════════════════════════
local function SellNow()
    pcall(function() R.Sell:InvokeServer() end)
    print("[FishIt] Semua dijual!")
end

task.spawn(function()
    while getgenv().FishIt_Running do
        if STATE.AutoSell then
            task.wait(CFG.SellInterval)
            if STATE.AutoSell then SellNow() end
        else
            task.wait(1)
        end
    end
end)

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 11: AUTO FAVORITE
--// ══════════════════════════════════════════════════════════════════════════
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
print("[FishIt] FishDB:", #FishDB)

local known = {}
local function CheckFav(item)
    if not item or known[item.UUID] then return end
    local tier = FishDB[item.Id]
    if tier and CFG.FavRarities[tier] and not item.Favorited then
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

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 12: AUTO WEATHER
--// ══════════════════════════════════════════════════════════════════════════
local WeatherConn = nil

local function StartWeather()
    if WeatherConn then WeatherConn:Disconnect() end
    
    pcall(function()
        local Replion = require(RS.Packages.Replion)
        local Events = Replion.Client:WaitReplion("Events")
        
        local function Check()
            if not STATE.AutoWeather or #CFG.WeatherTargets == 0 then return end
            local active = Events:Get("WeatherMachine") or {}
            
            for _, w in ipairs(CFG.WeatherTargets) do
                local found = false
                for _, a in ipairs(active) do
                    if a == w then found = true; break end
                end
                if not found then
                    pcall(function() R.Weather:InvokeServer(w) end)
                    print("[FishIt] Beli cuaca:", w)
                    task.wait(0.2)
                end
            end
        end
        
        WeatherConn = Events:OnChange("WeatherMachine", function()
            task.defer(Check)
        end)
        
        Check()
    end)
    
    print("[FishIt] Auto Cuaca started")
end

local function StopWeather()
    if WeatherConn then WeatherConn:Disconnect(); WeatherConn = nil end
    print("[FishIt] Auto Cuaca stopped")
end

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 13: AUTO EVENT
--// ══════════════════════════════════════════════════════════════════════════
local EventConn = nil
local EventSavedPos = nil
local EventActive = false

local function StartAutoEvent()
    if EventConn then EventConn:Disconnect() end
    
    EventConn = Workspace.DescendantAdded:Connect(function(inst)
        if not STATE.AutoEvent then return end
        if inst.Parent and inst.Parent.Name == "Props" then
            local h = HRP()
            if h then EventSavedPos = h.Position end
            EventActive = true
            task.wait(0.5)
            SafeTP(inst:GetPivot().Position + Vector3.new(0, 2, 0))
            print("[FishIt] Teleport ke event:", inst.Name)
        end
    end)
    
    print("[FishIt] Auto Event started")
end

local function StopAutoEvent()
    if EventConn then EventConn:Disconnect(); EventConn = nil end
    EventActive = false
    EventSavedPos = nil
    print("[FishIt] Auto Event stopped")
end

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 14: WATER WALK
--// ══════════════════════════════════════════════════════════════════════════
local WaterPart = nil
local WaterConn = nil

local function StartWater()
    if WaterPart then return end
    local h = HRP()
    if not h then return end
    
    local waterY = h.Position.Y - 2
    
    WaterPart = Instance.new("Part")
    WaterPart.Name = "FishIt_Water"
    WaterPart.Size = Vector3.new(18, 1, 18)
    WaterPart.Anchored = true
    WaterPart.CanCollide = true
    WaterPart.Transparency = 1
    WaterPart.Parent = Workspace
    
    WaterConn = RunService.Heartbeat:Connect(function()
        local hrp = HRP()
        if hrp and WaterPart then
            WaterPart.CFrame = CFrame.new(hrp.Position.X, waterY + 0.1, hrp.Position.Z)
        end
    end)
    
    print("[FishIt] Jalan di Air ON")
end

local function StopWater()
    if WaterConn then WaterConn:Disconnect(); WaterConn = nil end
    if WaterPart then WaterPart:Destroy(); WaterPart = nil end
    print("[FishIt] Jalan di Air OFF")
end

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 15: FPS BOOST
--// ══════════════════════════════════════════════════════════════════════════
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
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.Plastic
                    v.CastShadow = false
                end
            end)
        end
        print("[FishIt] Anti Lag ON")
    else
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            Lighting.GlobalShadows = true
            if setfpscap then setfpscap(60) end
        end)
        print("[FishIt] Anti Lag OFF")
    end
end

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 16: NO 3D RENDERING
--// ══════════════════════════════════════════════════════════════════════════
local function Toggle3D(off)
    STATE.No3D = off
    if RunService.Set3dRenderingEnabled then
        pcall(function() RunService:Set3dRenderingEnabled(not off) end)
        print("[FishIt] Hemat Baterai:", off and "ON" or "OFF")
    end
end

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 17: PERFORMANCE HUD
--// ══════════════════════════════════════════════════════════════════════════
local HUD = nil
local HUDConn = nil
local fps, frames, lastTick = 0, 0, os.clock()

RunService.RenderStepped:Connect(function()
    frames += 1
    if os.clock() - lastTick >= 1 then
        fps = frames
        frames = 0
        lastTick = os.clock()
    end
end)

local function CreateHUD()
    if HUD then return end
    
    HUD = Instance.new("ScreenGui")
    HUD.Name = "FishIt_HUD"
    HUD.ResetOnSpawn = false
    pcall(function() HUD.Parent = CoreGui end)
    if not HUD.Parent then HUD.Parent = PlayerGui end
    
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 180, 0, 70)
    f.Position = UDim2.new(0, 10, 0, 100)
    f.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    f.BackgroundTransparency = 0.2
    f.Parent = HUD
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -10, 1, 0)
    l.Position = UDim2.new(0, 5, 0, 0)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.fromRGB(200, 255, 200)
    l.TextSize = 12
    l.Font = Enum.Font.Code
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Top
    l.Parent = f
    
    HUDConn = RunService.Heartbeat:Connect(function()
        if not STATE.ShowHUD then return end
        
        local ping = 0
        pcall(function()
            ping = Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
        end)
        
        local mem = 0
        pcall(function()
            mem = math.floor(Stats:GetTotalMemoryUsageMb())
        end)
        
        l.Text = string.format(
            "FPS: %d\nPing: %dms\nMemory: %dMB\nIkan: %d",
            fps, ping, mem, STATE.Count
        )
    end)
end

local function ToggleHUD(on)
    STATE.ShowHUD = on
    if on then
        CreateHUD()
        HUD.Enabled = true
    else
        if HUD then HUD.Enabled = false end
    end
end

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 18: SERVER HOP / REJOIN
--// ══════════════════════════════════════════════════════════════════════════
local function ServerHop()
    print("[FishIt] Cari server baru...")
    
    local TPS = game:GetService("TeleportService")
    local Api = "https://games.roblox.com/v1/games/"
    local PlaceId = game.PlaceId
    
    local function List(cursor)
        local url = Api..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
        if cursor then url = url .. "&cursor=" .. cursor end
        return HttpService:JSONDecode(game:HttpGet(url))
    end
    
    local Server, Next
    repeat
        local Servers = List(Next)
        Server = Servers.data[1]
        Next = Servers.nextPageCursor
    until Server
    
    TPS:TeleportToPlaceInstance(PlaceId, Server.id, Player)
end

local function Rejoin()
    print("[FishIt] Rejoin...")
    game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
end

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 19: EQUIPMENT
--// ══════════════════════════════════════════════════════════════════════════
local function EquipTank()
    pcall(function() R.Tank:InvokeServer(105) end)
    print("[FishIt] Alat selam dipasang")
end

local function ToggleRadar(on)
    pcall(function() R.Radar:InvokeServer(on) end)
    print("[FishIt] Radar:", on and "ON" or "OFF")
end

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 20: ANTI-AFK
--// ══════════════════════════════════════════════════════════════════════════
pcall(function()
    if getconnections then
        for _, c in pairs(getconnections(Player.Idled)) do pcall(function() c:Disable() end) end
    end
    Player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
end)
print("[FishIt] Anti-AFK enabled")

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 21: SIDEBAR + TABS UI
--// ══════════════════════════════════════════════════════════════════════════
local G = Instance.new("ScreenGui")
G.Name = "FishIt_UI"
G.ResetOnSpawn = false
G.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() G.Parent = CoreGui end)
if not G.Parent then G.Parent = PlayerGui end

local C = {
    bg = Color3.fromRGB(18, 18, 22),
    sidebar = Color3.fromRGB(25, 25, 32),
    accent = Color3.fromRGB(80, 200, 120),
    text = Color3.fromRGB(255, 255, 255),
    textDim = Color3.fromRGB(150, 150, 150),
    btn = Color3.fromRGB(35, 35, 45),
    on = Color3.fromRGB(80, 200, 120),
    off = Color3.fromRGB(180, 60, 60),
    input = Color3.fromRGB(45, 45, 55),
}

-- Main Container
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 360, 0, 420)
Main.Position = UDim2.new(0.5, -180, 0.5, -210)
Main.BackgroundColor3 = C.bg
Main.BorderSizePixel = 0
Main.Parent = G
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)

-- Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 35)
TitleBar.BackgroundColor3 = C.accent
TitleBar.BorderSizePixel = 0
TitleBar.Parent = Main
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 12)

local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0, 15)
TitleFix.Position = UDim2.new(0, 0, 1, -15)
TitleFix.BackgroundColor3 = C.accent
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -40, 1, 0)
Title.Position = UDim2.new(0, 10, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🎣 Fish It Ultra"
Title.TextColor3 = C.text
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = TitleBar

-- Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 25, 0, 25)
CloseBtn.Position = UDim2.new(1, -30, 0.5, -12)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
CloseBtn.Text = "X"
CloseBtn.TextColor3 = C.text
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = TitleBar
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 55, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 35)
Sidebar.BackgroundColor3 = C.sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = Main

local SidebarCorner = Instance.new("Frame")
SidebarCorner.Size = UDim2.new(0, 12, 0, 12)
SidebarCorner.Position = UDim2.new(0, 0, 1, -12)
SidebarCorner.BackgroundColor3 = C.sidebar
SidebarCorner.BorderSizePixel = 0
SidebarCorner.Parent = Sidebar

Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 12)

-- Content Area
local Content = Instance.new("Frame")
Content.Size = UDim2.new(1, -60, 1, -40)
Content.Position = UDim2.new(0, 58, 0, 38)
Content.BackgroundTransparency = 1
Content.Parent = Main

-- Tab System
local tabs = {}
local pages = {}
local currentTab = nil

local function CreateSidebarTab(icon, name, order)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 45, 0, 45)
    btn.Position = UDim2.new(0, 5, 0, 5 + (order - 1) * 50)
    btn.BackgroundColor3 = C.btn
    btn.Text = icon
    btn.TextSize = 20
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = C.text
    btn.Parent = Sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.ScrollBarThickness = 4
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.Visible = false
    page.Parent = Content
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent = page
    
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 10)
    end)
    
    tabs[name] = btn
    pages[name] = page
    
    btn.MouseButton1Click:Connect(function()
        if currentTab then
            tabs[currentTab].BackgroundColor3 = C.btn
            pages[currentTab].Visible = false
        end
        currentTab = name
        btn.BackgroundColor3 = C.accent
        page.Visible = true
    end)
    
    return page
end

-- UI Helpers
local function Section(parent, text)
    local s = Instance.new("TextLabel")
    s.Size = UDim2.new(1, -10, 0, 20)
    s.BackgroundTransparency = 1
    s.Text = "━ " .. text .. " ━"
    s.TextColor3 = C.accent
    s.TextSize = 11
    s.Font = Enum.Font.GothamBold
    s.Parent = parent
end

local function Toggle(parent, name, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 36)
    f.BackgroundColor3 = C.btn
    f.BorderSizePixel = 0
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.7, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = name
    l.TextColor3 = C.text
    l.TextSize = 12
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 50, 0, 26)
    b.Position = UDim2.new(1, -60, 0.5, -13)
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

local function Button(parent, name, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 36)
    b.BackgroundColor3 = C.btn
    b.Text = name
    b.TextColor3 = C.text
    b.TextSize = 12
    b.Font = Enum.Font.Gotham
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    b.MouseButton1Click:Connect(callback)
end

local function NumberInput(parent, name, default, min, max, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 36)
    f.BackgroundColor3 = C.btn
    f.BorderSizePixel = 0
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.55, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = name
    l.TextColor3 = C.text
    l.TextSize = 11
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 70, 0, 26)
    box.Position = UDim2.new(1, -80, 0.5, -13)
    box.BackgroundColor3 = C.input
    box.Text = tostring(default)
    box.TextColor3 = C.text
    box.PlaceholderColor3 = C.textDim
    box.TextSize = 12
    box.Font = Enum.Font.GothamBold
    box.ClearTextOnFocus = false
    box.Parent = f
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)
    
    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num then
            num = math.clamp(num, min, max)
            box.Text = tostring(num)
            callback(num)
        else
            box.Text = tostring(default)
        end
    end)
    
    return function(v)
        box.Text = tostring(v)
    end
end

local function Dropdown(parent, name, options, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, -10, 0, 36)
    f.BackgroundColor3 = C.btn
    f.BorderSizePixel = 0
    f.Parent = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.4, 0, 1, 0)
    l.Position = UDim2.new(0, 10, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = name
    l.TextColor3 = C.text
    l.TextSize = 11
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    
    local idx = 1
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0.55, -15, 0, 26)
    b.Position = UDim2.new(0.45, 0, 0.5, -13)
    b.BackgroundColor3 = C.accent
    b.Text = options[1] or "Pilih"
    b.TextColor3 = C.text
    b.TextSize = 10
    b.Font = Enum.Font.GothamBold
    b.TextTruncate = Enum.TextTruncate.AtEnd
    b.Parent = f
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    
    b.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        b.Text = options[idx]
        callback(options[idx])
    end)
    
    return function(opts)
        options = opts
        idx = 1
        b.Text = options[1] or "Pilih"
    end
end

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 22: BUILD TABS
--// ══════════════════════════════════════════════════════════════════════════

-- TAB 1: MANCING
local fishPage = CreateSidebarTab("🎣", "Fish", 1)
Section(fishPage, "KONTROL MANCING")
Toggle(fishPage, "🎣 MULAI MANCING", false, function(v)
    if v then StartFish() else StopFish() end
end)
Dropdown(fishPage, "Mode", {"Turbo", "Normal"}, function(v)
    STATE.Turbo = (v == "Turbo")
    STATE.Blatant = false  -- Reset blatant when changing mode
end)
Toggle(fishPage, "Auto Perfect", true, function(v) STATE.AutoGreat = v end)
Button(fishPage, "🔧 Reset Stuck", Unstuck)

Section(fishPage, "⚡ BLATANT MODE")
Toggle(fishPage, "⚡ Blatant Mode (Flash!)", false, function(v)
    STATE.Blatant = v
    if v then STATE.Turbo = true end  -- Blatant requires turbo base
end)
NumberInput(fishPage, "Complete Delay", 0.01, 0, 0.5, function(v) CFG.CompleteDelay = v end)
NumberInput(fishPage, "Cancel Delay", 0.01, 0, 0.5, function(v) CFG.CancelDelay = v end)

Section(fishPage, "PENGATURAN DELAY")
NumberInput(fishPage, "Jeda Lempar", 0.9, 0.5, 3, function(v) CFG.ChargeDelay = v end)
NumberInput(fishPage, "Jeda Tarik", 0.4, 0.1, 2, function(v) CFG.CatchDelay = v end)
NumberInput(fishPage, "Jeda Reset", 0.1, 0.05, 1, function(v) CFG.ResetDelay = v end)

-- TAB 2: OTOMATIS
local autoPage = CreateSidebarTab("⚡", "Auto", 2)
Section(autoPage, "AUTO JUAL")
Toggle(autoPage, "Auto Jual", false, function(v) STATE.AutoSell = v end)
NumberInput(autoPage, "Waktu Jual (detik)", 60, 30, 300, function(v) CFG.SellInterval = v end)
Button(autoPage, "💰 Jual Sekarang", SellNow)

Section(autoPage, "AUTO FAVORITE")
Dropdown(autoPage, "Rarity", {"Mythic+Secret", "Legendary+", "Epic+", "Semua"}, function(v)
    CFG.FavRarities = {}
    if v == "Mythic+Secret" then CFG.FavRarities = {[6]=true, [7]=true}
    elseif v == "Legendary+" then CFG.FavRarities = {[5]=true, [6]=true, [7]=true}
    elseif v == "Epic+" then CFG.FavRarities = {[4]=true, [5]=true, [6]=true, [7]=true}
    else for i = 1, 7 do CFG.FavRarities[i] = true end end
end)
Toggle(autoPage, "Auto Favorite", false, function(v)
    STATE.AutoFav = v
    if v then ScanInv() end
end)

Section(autoPage, "AUTO CUACA")
Dropdown(autoPage, "Cuaca", {"Wind", "Cloudy", "Snow", "Storm", "Radiant"}, function(v)
    CFG.WeatherTargets = {v}
end)
Toggle(autoPage, "Auto Cuaca", false, function(v)
    STATE.AutoWeather = v
    if v then StartWeather() else StopWeather() end
end)

Section(autoPage, "AUTO EVENT")
Toggle(autoPage, "Auto Teleport Event", false, function(v)
    STATE.AutoEvent = v
    if v then StartAutoEvent() else StopAutoEvent() end
end)

-- TAB 3: TELEPORT
local tpPage = CreateSidebarTab("📍", "TP", 3)
Section(tpPage, "TELEPORT LOKASI")

local selectedWP = WPNames[1]
Dropdown(tpPage, "Lokasi", WPNames, function(v) selectedWP = v end)
Button(tpPage, "🚀 Teleport!", function()
    if WP[selectedWP] then TP(WP[selectedWP]) end
end)

Section(tpPage, "QUICK TELEPORT")
for _, name in ipairs({"Sisyphus Statue", "Esoteric Depths", "Treasure Room", "Iron Cavern", "Pirate Cove"}) do
    Button(tpPage, "📍 " .. name, function() TP(WP[name]) end)
end

Section(tpPage, "TELEPORT PLAYER")
local playerList = GetPlayers()
local selectedPlayer = playerList[1] or ""
local refreshPlayers = Dropdown(tpPage, "Player", #playerList > 0 and playerList or {"Kosong"}, function(v)
    selectedPlayer = v
end)
Button(tpPage, "👤 TP ke Player", function()
    local p = Players:FindFirstChild(selectedPlayer)
    if p and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
        TP(p.Character.HumanoidRootPart.Position + Vector3.new(3, 0, 0))
    end
end)
Button(tpPage, "🔄 Refresh", function()
    playerList = GetPlayers()
    refreshPlayers(#playerList > 0 and playerList or {"Kosong"})
end)

-- TAB 4: LAINNYA
local miscPage = CreateSidebarTab("⚙️", "Misc", 4)
Section(miscPage, "PERFORMA")
Toggle(miscPage, "Anti Lag", false, ToggleFPS)
Toggle(miscPage, "Hemat Baterai", false, Toggle3D)
Toggle(miscPage, "Tampilkan HUD", false, ToggleHUD)

Section(miscPage, "UTILITY")
Toggle(miscPage, "Jalan di Air", false, function(v)
    STATE.WaterWalk = v
    if v then StartWater() else StopWater() end
end)
Toggle(miscPage, "Radar Ikan", false, ToggleRadar)
Button(miscPage, "🤿 Pasang Alat Selam", EquipTank)

Section(miscPage, "SERVER")
Button(miscPage, "🔄 Ganti Server", ServerHop)
Button(miscPage, "🔄 Rejoin", Rejoin)

-- Select first tab
tabs["Fish"].BackgroundColor3 = C.accent
pages["Fish"].Visible = true
currentTab = "Fish"

--// ══════════════════════════════════════════════════════════════════════════
--// SECTION 23: DRAGGABLE
--// ══════════════════════════════════════════════════════════════════════════
local dragging, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

TitleBar.InputEnded:Connect(function(input)
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
--// SECTION 24: TOGGLE BUTTON
--// ══════════════════════════════════════════════════════════════════════════
local Btn = Instance.new("TextButton")
Btn.Size = UDim2.new(0, 50, 0, 50)
Btn.Position = UDim2.new(0, 10, 0.5, -25)
Btn.BackgroundColor3 = C.accent
Btn.Text = "🎣"
Btn.TextSize = 22
Btn.Parent = G
Instance.new("UICorner", Btn).CornerRadius = UDim.new(1, 0)

Btn.MouseButton1Click:Connect(function() Main.Visible = not Main.Visible end)

-- Draggable button
local btnDrag, btnStart, btnPos

Btn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        btnDrag = true
        btnStart = input.Position
        btnPos = Btn.Position
    end
end)

Btn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        btnDrag = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if btnDrag and input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - btnStart
        Btn.Position = UDim2.new(btnPos.X.Scale, btnPos.X.Offset + delta.X, btnPos.Y.Scale, btnPos.Y.Offset + delta.Y)
    end
end)

--// ══════════════════════════════════════════════════════════════════════════
--// DONE
--// ══════════════════════════════════════════════════════════════════════════
print([[
╔═══════════════════════════════════════════════════════════════════════════╗
║                    FISH IT - ULTRA EDITION LOADED                         ║
╠═══════════════════════════════════════════════════════════════════════════╣
║  • Sidebar UI dengan 4 Tab                                                ║
║  • Ultra-Turbo Fishing (3+ ikan cepat)                                    ║
║  • Input Number (bukan slider)                                            ║
║  • Tap tombol 🎣 untuk buka/tutup                                         ║
╚═══════════════════════════════════════════════════════════════════════════╝
]])
