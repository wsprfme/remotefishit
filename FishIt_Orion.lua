--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                         FISH IT - ORION EDITION                           ║
    ║                    Full Featured • Lightweight • Android                  ║
    ║                                                                           ║
    ║  Features:                                                                ║
    ║  ✅ Auto Fish (Normal & Turbo)    ✅ Auto Sell (Timer)                    ║
    ║  ✅ Auto Favorite (Rarity)        ✅ 22 Teleport Locations                ║
    ║  ✅ Anti-AFK                      ✅ FPS Boost                            ║
    ║  ✅ Water Walk                    ✅ Fishing Blocker                      ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 1: CLEANUP & INITIALIZATION
--// ═══════════════════════════════════════════════════════════════════════════

-- Stop previous instance
if getgenv().FishIt_Running then
    getgenv().FishIt_Running = false
    task.wait(0.5)
end

-- Cleanup old UI
pcall(function()
    for _, gui in pairs(game:GetService("CoreGui"):GetChildren()) do
        if gui.Name == "Orion" or gui.Name == "FishIt_Orion" then
            gui:Destroy()
        end
    end
end)

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 2: SERVICES
--// ═══════════════════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Reconnect on respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
end)

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 3: NETWORK REMOTES
--// ═══════════════════════════════════════════════════════════════════════════

local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net

local Remotes = {
    ChargeRod = net["RF/ChargeFishingRod"],
    RequestGame = net["RF/RequestFishingMinigameStarted"],
    CompleteGame = net["RE/FishingCompleted"],
    CancelInput = net["RF/CancelFishingInputs"],
    SellAll = net["RF/SellAllItems"],
    EquipTool = net["RE/EquipToolFromHotbar"],
    UnequipTool = net["RE/UnequipToolFromHotbar"],
    FavoriteItem = net["RE/FavoriteItem"],
    AutoGreat = net["RF/UpdateAutoFishingState"],
    EquipTank = net["RF/EquipOxygenTank"],
    UpdateRadar = net["RF/UpdateFishingRadar"],
    ObtainedFish = net["RE/ObtainedNewFishNotification"],
}

print("[FishIt] Network remotes loaded")

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 4: FISHING PARAMETERS
--// ═══════════════════════════════════════════════════════════════════════════

local FishArgs = { -1.115296483039856, 0, 1763651451.636425 }

local Config = {
    -- Delays
    DelayCharge = 1.15,
    DelayTime = 0.56,
    DelayReset = 0.2,
    
    -- Auto Sell
    SellInterval = 60,
    
    -- Rarity (tier numbers)
    FavoriteRarities = { [6] = true, [7] = true }, -- Mythic, Secret
}

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 5: STATE MANAGEMENT
--// ═══════════════════════════════════════════════════════════════════════════

local State = {
    -- Fishing
    FishingActive = false,
    TurboMode = true,
    AutoGreat = true,
    BlockerEnabled = false,
    
    -- Auto Features
    AutoSell = false,
    AutoFavorite = false,
    
    -- Utils
    AntiAFK = true,
    WaterWalk = false,
    FPSBoost = false,
    
    -- Stats
    FishCount = 0,
}

getgenv().FishIt_Running = true
getgenv().FishIt_State = State

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 6: WAYPOINTS (22 LOCATIONS)
--// ═══════════════════════════════════════════════════════════════════════════

local Waypoints = {
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
    ["Iron Cafe"] = Vector3.new(-8647, -548, 160),
    ["Crater Island"] = Vector3.new(1070, 2, 5102),
    ["Christmas Island"] = Vector3.new(1175, 24, 1558),
    ["Underground Cellar"] = Vector3.new(2135, -91, -700),
    ["Christmas Cave"] = Vector3.new(715, -487, 8910),
    ["Mount Hallow"] = Vector3.new(2136, 78, 3272),
}

-- Get sorted names for dropdown
local WaypointNames = {}
for name in pairs(Waypoints) do
    table.insert(WaypointNames, name)
end
table.sort(WaypointNames)

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 7: UTILITY FUNCTIONS
--// ═══════════════════════════════════════════════════════════════════════════

local function GetHRP()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function TeleportTo(position)
    local hrp = GetHRP()
    if hrp then
        hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        hrp.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
        return true
    end
    return false
end

local function Notify(title, content)
    -- OrionLib notification (will be set after UI load)
    if getgenv().FishIt_Orion then
        pcall(function()
            getgenv().FishIt_Orion:MakeNotification({
                Name = title,
                Content = content,
                Time = 3
            })
        end)
    end
    print("[FishIt]", title, "-", content)
end

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 8: FISHING BLOCKER (hookmetamethod)
--// ═══════════════════════════════════════════════════════════════════════════

local BlockedRemotes = {
    [Remotes.ChargeRod] = true,
    [Remotes.RequestGame] = true,
    [Remotes.CompleteGame] = true,
    [Remotes.CancelInput] = true,
}

if hookmetamethod and checkcaller then
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        
        if State.BlockerEnabled and BlockedRemotes[self] and not checkcaller() then
            if method == "InvokeServer" then
                return task.wait(9e9) -- Freeze forever
            elseif method == "FireServer" then
                return nil
            end
        end
        
        return oldNamecall(self, ...)
    end)
    print("[FishIt] Fishing blocker installed")
else
    warn("[FishIt] hookmetamethod not available - blocker disabled")
end

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 9: SPAWN LIMITER (for turbo mode)
--// ═══════════════════════════════════════════════════════════════════════════

local MAX_PARALLEL = 4
local activeSpawns = 0

local function LightSpawn(fn)
    if activeSpawns >= MAX_PARALLEL then return end
    
    activeSpawns = activeSpawns + 1
    task.spawn(function()
        pcall(fn)
        activeSpawns = activeSpawns - 1
    end)
end

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 10: FISHING LOGIC
--// ═══════════════════════════════════════════════════════════════════════════

local function EnableAutoGreat()
    if State.AutoGreat then
        pcall(function()
            Remotes.AutoGreat:InvokeServer(true)
        end)
    end
end

local function DisableAutoGreat()
    pcall(function()
        Remotes.AutoGreat:InvokeServer(false)
    end)
end

-- Normal Fishing Loop (Instant mode)
local function NormalFishingLoop()
    while State.FishingActive and not State.TurboMode do
        pcall(function() Remotes.ChargeRod:InvokeServer() end)
        task.wait(0.055)
        
        if not State.FishingActive then break end
        
        pcall(function() Remotes.RequestGame:InvokeServer(unpack(FishArgs)) end)
        task.wait(Config.DelayTime)
        
        if not State.FishingActive then break end
        
        pcall(function() Remotes.CompleteGame:FireServer() end)
        task.wait(0.05)
        
        pcall(function() Remotes.CancelInput:InvokeServer() end)
        
        State.FishCount = State.FishCount + 1
    end
end

-- Turbo Fishing Loop (Blatant mode)
local function TurboFishingLoop()
    pcall(function() Remotes.CancelInput:InvokeServer() end)
    task.wait(0.055)
    
    while State.FishingActive and State.TurboMode do
        LightSpawn(function()
            Remotes.ChargeRod:InvokeServer()
        end)
        task.wait(0.01)
        
        LightSpawn(function()
            Remotes.RequestGame:InvokeServer(unpack(FishArgs))
        end)
        task.wait(Config.DelayCharge)
        
        pcall(function() Remotes.CompleteGame:FireServer() end)
        task.wait(Config.DelayReset)
        
        pcall(function() Remotes.CancelInput:InvokeServer() end)
        task.wait(0.01)
        
        State.FishCount = State.FishCount + 1
    end
end

local function StartFishing()
    if State.FishingActive then return end
    
    State.FishingActive = true
    State.BlockerEnabled = true
    EnableAutoGreat()
    
    Notify("Fishing", "Started " .. (State.TurboMode and "(TURBO)" or "(Normal)"))
    
    task.spawn(function()
        while State.FishingActive do
            if State.TurboMode then
                TurboFishingLoop()
            else
                NormalFishingLoop()
            end
            task.wait(0.1)
        end
    end)
end

local function StopFishing()
    State.FishingActive = false
    State.BlockerEnabled = false
    
    DisableAutoGreat()
    pcall(function() Remotes.CompleteGame:FireServer() end)
    pcall(function() Remotes.CancelInput:InvokeServer() end)
    
    Notify("Fishing", "Stopped - Caught: " .. State.FishCount)
end

local function UnstuckFishing()
    pcall(function() Remotes.CompleteGame:FireServer() end)
    pcall(function() Remotes.CancelInput:InvokeServer() end)
    Notify("Unstuck", "Reset fishing state")
end

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 11: AUTO SELL
--// ═══════════════════════════════════════════════════════════════════════════

local function SellAll()
    local success = pcall(function()
        return Remotes.SellAll:InvokeServer()
    end)
    
    if success then
        Notify("Sell", "Sold all items!")
    end
    return success
end

local function StartAutoSellLoop()
    task.spawn(function()
        while getgenv().FishIt_Running do
            if State.AutoSell then
                for i = 1, Config.SellInterval do
                    if not State.AutoSell then break end
                    task.wait(1)
                end
                if State.AutoSell then
                    SellAll()
                end
            else
                task.wait(1)
            end
        end
    end)
end

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 12: AUTO FAVORITE
--// ═══════════════════════════════════════════════════════════════════════════

local FishDB = {}
local KnownUUIDs = {}

-- Load Fish Database
local function LoadFishDB()
    pcall(function()
        for _, module in ipairs(ReplicatedStorage.Items:GetChildren()) do
            if module:IsA("ModuleScript") then
                local ok, mod = pcall(require, module)
                if ok and mod and mod.Data and mod.Data.Type == "Fish" then
                    FishDB[mod.Data.Id] = mod.Data.Tier
                end
            end
        end
    end)
    print("[FishIt] FishDB loaded:", #FishDB, "fish types")
end

local RarityNames = {
    [1] = "Common", [2] = "Uncommon", [3] = "Rare", [4] = "Epic",
    [5] = "Legendary", [6] = "Mythic", [7] = "Secret"
}

local function FavoriteIfMatch(item)
    if not item or KnownUUIDs[item.UUID] then return end
    
    local tier = FishDB[item.Id]
    if not tier then return end
    
    if Config.FavoriteRarities[tier] and not item.Favorited then
        pcall(function()
            Remotes.FavoriteItem:FireServer(item.UUID)
        end)
        print("[FishIt] Favorited:", RarityNames[tier] or "Unknown")
    end
    
    KnownUUIDs[item.UUID] = true
end

local function ScanInventory()
    pcall(function()
        local Replion = require(ReplicatedStorage.Packages.Replion)
        local Data = Replion.Client:WaitReplion("Data")
        local inv = Data:Get("Inventory")
        
        if inv and inv.Items then
            for _, item in pairs(inv.Items) do
                FavoriteIfMatch(item)
            end
        end
    end)
end

local newFishConnection = nil

local function StartAutoFavorite()
    LoadFishDB()
    KnownUUIDs = {}
    ScanInventory()
    
    if newFishConnection then
        newFishConnection:Disconnect()
    end
    
    newFishConnection = Remotes.ObtainedFish.OnClientEvent:Connect(function()
        if State.AutoFavorite then
            task.defer(ScanInventory)
        end
    end)
    
    Notify("Auto Favorite", "Enabled")
end

local function StopAutoFavorite()
    if newFishConnection then
        newFishConnection:Disconnect()
        newFishConnection = nil
    end
    
    Notify("Auto Favorite", "Disabled")
end

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 13: ANTI-AFK
--// ═══════════════════════════════════════════════════════════════════════════

local function StartAntiAFK()
    -- Disable existing Idled connections
    if getconnections then
        for _, conn in pairs(getconnections(LocalPlayer.Idled)) do
            pcall(function() conn:Disable() end)
        end
    end
    
    LocalPlayer.Idled:Connect(function()
        if State.AntiAFK then
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
            print("[FishIt] Anti-AFK triggered")
        end
    end)
    
    print("[FishIt] Anti-AFK enabled")
end

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 14: WATER WALK
--// ═══════════════════════════════════════════════════════════════════════════

local WaterPlatform = nil
local WaterConnection = nil

local function ToggleWaterWalk(enabled)
    State.WaterWalk = enabled
    
    if enabled then
        local hrp = GetHRP()
        if not hrp then return end
        
        local waterY = hrp.Position.Y - 2
        
        WaterPlatform = Instance.new("Part")
        WaterPlatform.Name = "FishIt_WaterPlatform"
        WaterPlatform.Size = Vector3.new(18, 1, 18)
        WaterPlatform.Anchored = true
        WaterPlatform.CanCollide = true
        WaterPlatform.Transparency = 1
        WaterPlatform.Parent = Workspace
        
        WaterConnection = RunService.Heartbeat:Connect(function()
            local hrpNow = GetHRP()
            if hrpNow and WaterPlatform then
                WaterPlatform.CFrame = CFrame.new(
                    hrpNow.Position.X,
                    waterY + 0.1,
                    hrpNow.Position.Z
                )
            end
        end)
        
        Notify("Water Walk", "Enabled")
    else
        if WaterConnection then
            WaterConnection:Disconnect()
            WaterConnection = nil
        end
        
        if WaterPlatform then
            WaterPlatform:Destroy()
            WaterPlatform = nil
        end
        
        Notify("Water Walk", "Disabled")
    end
end

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 15: FPS BOOST
--// ═══════════════════════════════════════════════════════════════════════════

local function ToggleFPSBoost(enabled)
    State.FPSBoost = enabled
    
    if enabled then
        pcall(function()
            settings().Rendering.QualityLevel = 1
            game.Lighting.GlobalShadows = false
            if setfpscap then setfpscap(30) end
        end)
        
        -- Reduce material quality
        for _, v in pairs(game:GetDescendants()) do
            pcall(function()
                if v:IsA("BasePart") then
                    v.Material = Enum.Material.Plastic
                    v.CastShadow = false
                end
            end)
        end
        
        Notify("FPS Boost", "Enabled (Potato Mode)")
    else
        pcall(function()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
            game.Lighting.GlobalShadows = true
            if setfpscap then setfpscap(60) end
        end)
        
        Notify("FPS Boost", "Disabled")
    end
end

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 16: NO 3D RENDERING (Extreme FPS Boost)
--// ═══════════════════════════════════════════════════════════════════════════

local No3DActive = false

local function ToggleNo3D(enabled)
    if not RunService.Set3dRenderingEnabled then
        Notify("Error", "No 3D control not supported")
        return
    end
    
    No3DActive = enabled
    
    pcall(function()
        RunService:Set3dRenderingEnabled(not enabled)
    end)
    
    Notify("3D Rendering", enabled and "Disabled (Extreme)" or "Enabled")
end

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 17: ORION UI LIBRARY
--// ═══════════════════════════════════════════════════════════════════════════

local OrionLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Orion/main/source"))()

getgenv().FishIt_Orion = OrionLib

OrionLib:MakeNotification({
    Name = "Fish It",
    Content = "Loading UI...",
    Time = 2
})

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 18: CREATE UI WINDOW
--// ═══════════════════════════════════════════════════════════════════════════

local Window = OrionLib:MakeWindow({
    Name = "🎣 Fish It - Orion Edition",
    HidePremium = true,
    SaveConfig = true,
    ConfigFolder = "FishIt_Orion",
    IntroEnabled = false
})

--// ═══════════════════════════════════════════════════════════════════════════
--// TAB 1: FISHING
--// ═══════════════════════════════════════════════════════════════════════════

local FishingTab = Window:MakeTab({
    Name = "🎣 Fishing",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

FishingTab:AddSection({ Name = "Fishing Mode" })

FishingTab:AddDropdown({
    Name = "Fishing Mode",
    Default = "Turbo",
    Options = {"Normal", "Turbo"},
    Callback = function(value)
        State.TurboMode = (value == "Turbo")
    end
})

FishingTab:AddSlider({
    Name = "Charge Delay",
    Min = 0.5,
    Max = 2,
    Default = 1.15,
    Color = Color3.fromRGB(100, 200, 100),
    Increment = 0.05,
    ValueName = "sec",
    Callback = function(value)
        Config.DelayCharge = value
    end
})

FishingTab:AddSlider({
    Name = "Catch Delay",
    Min = 0.3,
    Max = 2,
    Default = 0.56,
    Color = Color3.fromRGB(100, 200, 100),
    Increment = 0.05,
    ValueName = "sec",
    Callback = function(value)
        Config.DelayTime = value
    end
})

FishingTab:AddSection({ Name = "Controls" })

FishingTab:AddToggle({
    Name = "Auto Great Catch",
    Default = true,
    Callback = function(value)
        State.AutoGreat = value
    end
})

FishingTab:AddToggle({
    Name = "🎣 Start Fishing",
    Default = false,
    Callback = function(value)
        if value then
            StartFishing()
        else
            StopFishing()
        end
    end
})

FishingTab:AddButton({
    Name = "🔧 Unstuck",
    Callback = function()
        UnstuckFishing()
    end
})

FishingTab:AddLabel("Fish Caught: " .. State.FishCount)

--// ═══════════════════════════════════════════════════════════════════════════
--// TAB 2: AUTO FEATURES
--// ═══════════════════════════════════════════════════════════════════════════

local AutoTab = Window:MakeTab({
    Name = "⚡ Auto",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

AutoTab:AddSection({ Name = "Auto Sell" })

AutoTab:AddToggle({
    Name = "Auto Sell",
    Default = false,
    Callback = function(value)
        State.AutoSell = value
        Notify("Auto Sell", value and "Enabled" or "Disabled")
    end
})

AutoTab:AddSlider({
    Name = "Sell Interval",
    Min = 30,
    Max = 300,
    Default = 60,
    Color = Color3.fromRGB(255, 200, 100),
    Increment = 10,
    ValueName = "sec",
    Callback = function(value)
        Config.SellInterval = value
    end
})

AutoTab:AddButton({
    Name = "💰 Sell Now",
    Callback = function()
        SellAll()
    end
})

AutoTab:AddSection({ Name = "Auto Favorite" })

AutoTab:AddDropdown({
    Name = "Favorite Rarities",
    Default = {"Mythic", "Secret"},
    Options = {"Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret"},
    Multi = true,
    Callback = function(selected)
        Config.FavoriteRarities = {}
        local map = { Common=1, Uncommon=2, Rare=3, Epic=4, Legendary=5, Mythic=6, Secret=7 }
        for _, rarity in pairs(selected) do
            Config.FavoriteRarities[map[rarity]] = true
        end
    end
})

AutoTab:AddToggle({
    Name = "Auto Favorite",
    Default = false,
    Callback = function(value)
        State.AutoFavorite = value
        if value then
            StartAutoFavorite()
        else
            StopAutoFavorite()
        end
    end
})

--// ═══════════════════════════════════════════════════════════════════════════
--// TAB 3: TELEPORT
--// ═══════════════════════════════════════════════════════════════════════════

local TeleportTab = Window:MakeTab({
    Name = "📍 Teleport",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

TeleportTab:AddSection({ Name = "Islands" })

local SelectedLocation = "Sisyphus Statue"

TeleportTab:AddDropdown({
    Name = "Select Location",
    Default = "Sisyphus Statue",
    Options = WaypointNames,
    Callback = function(value)
        SelectedLocation = value
    end
})

TeleportTab:AddButton({
    Name = "🚀 Teleport",
    Callback = function()
        local pos = Waypoints[SelectedLocation]
        if pos then
            TeleportTo(pos)
            Notify("Teleport", "Moved to " .. SelectedLocation)
        end
    end
})

TeleportTab:AddSection({ Name = "Quick Teleport" })

TeleportTab:AddButton({
    Name = "Sisyphus Statue",
    Callback = function() TeleportTo(Waypoints["Sisyphus Statue"]) end
})

TeleportTab:AddButton({
    Name = "Esoteric Depths",
    Callback = function() TeleportTo(Waypoints["Esoteric Depths"]) end
})

TeleportTab:AddButton({
    Name = "Treasure Room",
    Callback = function() TeleportTo(Waypoints["Treasure Room"]) end
})

TeleportTab:AddButton({
    Name = "Iron Cavern",
    Callback = function() TeleportTo(Waypoints["Iron Cavern"]) end
})

TeleportTab:AddSection({ Name = "Coordinates" })

TeleportTab:AddButton({
    Name = "📋 Copy Current Position",
    Callback = function()
        local hrp = GetHRP()
        if hrp then
            local pos = hrp.Position
            local str = string.format("Vector3.new(%.0f, %.0f, %.0f)", pos.X, pos.Y, pos.Z)
            if setclipboard then
                setclipboard(str)
                Notify("Copied", str)
            else
                print("[FishIt] Position:", str)
                Notify("Position", str)
            end
        end
    end
})

--// ═══════════════════════════════════════════════════════════════════════════
--// TAB 4: SETTINGS
--// ═══════════════════════════════════════════════════════════════════════════

local SettingsTab = Window:MakeTab({
    Name = "⚙️ Settings",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

SettingsTab:AddSection({ Name = "Performance" })

SettingsTab:AddToggle({
    Name = "FPS Boost (Potato)",
    Default = false,
    Callback = function(value)
        ToggleFPSBoost(value)
    end
})

SettingsTab:AddToggle({
    Name = "No 3D Rendering (Extreme)",
    Default = false,
    Callback = function(value)
        ToggleNo3D(value)
    end
})

SettingsTab:AddSection({ Name = "Player" })

SettingsTab:AddToggle({
    Name = "Water Walk",
    Default = false,
    Callback = function(value)
        ToggleWaterWalk(value)
    end
})

SettingsTab:AddToggle({
    Name = "Anti-AFK",
    Default = true,
    Callback = function(value)
        State.AntiAFK = value
        Notify("Anti-AFK", value and "Enabled" or "Disabled")
    end
})

SettingsTab:AddSection({ Name = "Equipment" })

SettingsTab:AddButton({
    Name = "Equip Diving Gear",
    Callback = function()
        pcall(function() Remotes.EquipTank:InvokeServer(105) end)
        Notify("Equipment", "Diving gear equipped")
    end
})

SettingsTab:AddToggle({
    Name = "Toggle Radar",
    Default = false,
    Callback = function(value)
        pcall(function() Remotes.UpdateRadar:InvokeServer(value) end)
        Notify("Radar", value and "Enabled" or "Disabled")
    end
})

SettingsTab:AddSection({ Name = "Server" })

SettingsTab:AddButton({
    Name = "🔄 Server Hop",
    Callback = function()
        Notify("Server", "Finding new server...")
        
        local TPS = game:GetService("TeleportService")
        local Api = "https://games.roblox.com/v1/games/"
        local PlaceId = game.PlaceId
        
        local function ListServers(cursor)
            local url = Api..PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
            if cursor then url = url .. "&cursor=" .. cursor end
            local Raw = game:HttpGet(url)
            return HttpService:JSONDecode(Raw)
        end
        
        local Server, Next
        repeat
            local Servers = ListServers(Next)
            Server = Servers.data[1]
            Next = Servers.nextPageCursor
        until Server
        
        TPS:TeleportToPlaceInstance(PlaceId, Server.id, LocalPlayer)
    end
})

SettingsTab:AddButton({
    Name = "🔄 Rejoin (Auto-Execute)",
    Callback = function()
        Notify("Server", "Rejoining...")
        
        local script = [[loadstring(game:HttpGet("YOUR_SCRIPT_URL"))()]]
        
        if syn and syn.queue_on_teleport then
            syn.queue_on_teleport(script)
        elseif queue_on_teleport then
            queue_on_teleport(script)
        end
        
        game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
    end
})

--// ═══════════════════════════════════════════════════════════════════════════
--// SECTION 19: INITIALIZE
--// ═══════════════════════════════════════════════════════════════════════════

StartAntiAFK()
StartAutoSellLoop()
LoadFishDB()

OrionLib:Init()

OrionLib:MakeNotification({
    Name = "Fish It - Orion Edition",
    Content = "Ready! Press RightControl to toggle UI",
    Time = 5
})

print([[
╔═══════════════════════════════════════════════════════════════════════════╗
║                    FISH IT - ORION EDITION LOADED                         ║
╠═══════════════════════════════════════════════════════════════════════════╣
║  Toggle UI: RightControl                                                  ║
║  Features: Auto Fish, Auto Sell, Auto Favorite, 22 Teleports              ║
╚═══════════════════════════════════════════════════════════════════════════╝
]])
