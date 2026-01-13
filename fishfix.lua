--[[
    ╔═══════════════════════════════════════════════════════════════════════════╗
    ║                         🎣 FISH IT AUTO                                   ║
    ║                     Simple • Fast • Android Ready                         ║
    ╚═══════════════════════════════════════════════════════════════════════════╝
]]

--// CLEANUP
if getgenv().FishIt then getgenv().FishIt = false task.wait(0.3) end
pcall(function()
    for _, g in pairs(game:GetService("CoreGui"):GetChildren()) do
        if g.Name:find("FishIt") then g:Destroy() end
    end
end)

--// SERVICES
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Run = game:GetService("RunService")
local Virtual = game:GetService("VirtualUser")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local Http = game:GetService("HttpService")
local Light = game:GetService("Lighting")
local Work = game:GetService("Workspace")

local Me = Players.LocalPlayer

--// REMOTES
local net = RS.Packages._Index["sleitnick_net@0.2.0"].net

local Remote = {
    Charge = net["RF/ChargeFishingRod"],
    Start = net["RF/RequestFishingMinigameStarted"],
    Done = net["RE/FishingCompleted"],
    Reset = net["RF/CancelFishingInputs"],
    Sell = net["RF/SellAllItems"],
    Favorite = net["RE/FavoriteItem"],
    AutoGreat = net["RF/UpdateAutoFishingState"],
    NewFish = net["RE/ObtainedNewFishNotification"],
}

--// SETTINGS
local FishArgs = {-1.115296483039856, 0, 1763651451.636425}

local Setting = {
    Speed = "Super Fast",  -- Normal / Fast / Super Fast
    MaxFish = 9,           -- Max parallel fishing (up to 9)
    SellTimer = 60,        -- Auto sell every X seconds
    FavRarity = 6,         -- Favorite rarity 6+ (Mythic, Secret)
}

local Status = {
    Fishing = false,
    AutoSell = false,
    AutoFav = false,
    Count = 0,
}

getgenv().FishIt = true

--// TELEPORT SPOTS
local Spots = {
    ["🏝️ Spawn Island"] = Vector3.new(-33, 10, 2770),
    ["🗿 Sisyphus"] = Vector3.new(-3657, -134, -963),
    ["🌊 Esoteric Depths"] = Vector3.new(3240, -1302, 1404),
    ["💎 Treasure Room"] = Vector3.new(-3604, -284, -1632),
    ["🪨 Iron Cavern"] = Vector3.new(-8798, -585, 241),
    ["🪸 Coral Reef"] = Vector3.new(-3138, 4, 2132),
    ["🌴 Kohana"] = Vector3.new(-626, 16, 588),
    ["🔥 Kohana Lava"] = Vector3.new(-594, 59, 112),
    ["🌿 Ancient Jungle"] = Vector3.new(1463, 8, -358),
    ["⛩️ Sacred Temple"] = Vector3.new(1476, -22, -632),
    ["🏝️ Classic Island"] = Vector3.new(1433, 44, 2755),
    ["🌋 Crater Island"] = Vector3.new(1070, 2, 5102),
    ["🎄 Christmas Island"] = Vector3.new(1175, 24, 1558),
    ["❄️ Christmas Cave"] = Vector3.new(715, -487, 8910),
    ["🏜️ Ancient Ruin"] = Vector3.new(6067, -586, 4714),
    ["🌧️ Weather Machine"] = Vector3.new(-1517, 3, 1910),
    ["🏴‍☠️ Pirate Cove"] = Vector3.new(3405, 10, 3350),
    ["🌳 Tropical Grove"] = Vector3.new(-2132, 53, 3630),
    ["🕳️ Underground"] = Vector3.new(2135, -91, -700),
    ["🏔️ Esoteric Island"] = Vector3.new(1991, 6, 1390),
}

local SpotNames = {}
for n in pairs(Spots) do table.insert(SpotNames, n) end
table.sort(SpotNames)

--// HELPERS
local function HRP()
    local c = Me.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GoTo(pos)
    local h = HRP()
    if h then
        h.AssemblyLinearVelocity = Vector3.zero
        h.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
    end
end

--// FISHING BLOCKER - Block game's fishing when we're fishing
local Blocked = {[Remote.Charge]=1, [Remote.Start]=1, [Remote.Done]=1, [Remote.Reset]=1}

if hookmetamethod and checkcaller then
    local old
    old = hookmetamethod(game, "__namecall", function(self, ...)
        local m = getnamecallmethod()
        if Status.Fishing and Blocked[self] and not checkcaller() then
            if m == "InvokeServer" then return task.wait(9e9) end
            if m == "FireServer" then return end
        end
        return old(self, ...)
    end)
end

--// PARALLEL FISHING - Up to 9 fish at once!
local active = 0

local function CatchOneFish()
    if active >= Setting.MaxFish then return end
    active = active + 1
    
    task.spawn(function()
        pcall(function() Remote.Charge:InvokeServer() end)
        task.wait(0.01)
        pcall(function() Remote.Start:InvokeServer(unpack(FishArgs)) end)
        
        -- Speed settings
        if Setting.Speed == "Super Fast" then
            task.wait(0.8)
        elseif Setting.Speed == "Fast" then
            task.wait(1.0)
        else
            task.wait(1.3)
        end
        
        pcall(function() Remote.Done:FireServer() end)
        task.wait(0.1)
        pcall(function() Remote.Reset:InvokeServer() end)
        
        Status.Count = Status.Count + 1
        active = active - 1
    end)
end

local function StartFishing()
    if Status.Fishing then return end
    Status.Fishing = true
    
    -- Enable auto great catch
    pcall(function() Remote.AutoGreat:InvokeServer(true) end)
    pcall(function() Remote.Reset:InvokeServer() end)
    
    task.spawn(function()
        while Status.Fishing do
            -- Spawn multiple fish catches in parallel
            for i = 1, Setting.MaxFish do
                if not Status.Fishing then break end
                CatchOneFish()
                task.wait(0.05) -- Small delay between spawns
            end
            task.wait(0.3) -- Wait before next batch
        end
    end)
end

local function StopFishing()
    Status.Fishing = false
    pcall(function() Remote.AutoGreat:InvokeServer(false) end)
    pcall(function() Remote.Done:FireServer() end)
    pcall(function() Remote.Reset:InvokeServer() end)
end

--// AUTO SELL
task.spawn(function()
    while getgenv().FishIt do
        if Status.AutoSell then
            task.wait(Setting.SellTimer)
            if Status.AutoSell then
                pcall(function() Remote.Sell:InvokeServer() end)
            end
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

local known = {}
pcall(function()
    Remote.NewFish.OnClientEvent:Connect(function()
        if not Status.AutoFav then return end
        task.defer(function()
            pcall(function()
                local Replion = require(RS.Packages.Replion)
                local Data = Replion.Client:WaitReplion("Data")
                local inv = Data:Get("Inventory")
                if inv and inv.Items then
                    for _, item in pairs(inv.Items) do
                        if not known[item.UUID] then
                            local tier = FishDB[item.Id]
                            if tier and tier >= Setting.FavRarity and not item.Favorited then
                                pcall(function() Remote.Favorite:FireServer(item.UUID) end)
                            end
                            known[item.UUID] = true
                        end
                    end
                end
            end)
        end)
    end)
end)

--// ANTI-AFK
pcall(function()
    if getconnections then
        for _, c in pairs(getconnections(Me.Idled)) do pcall(function() c:Disable() end) end
    end
    Me.Idled:Connect(function()
        Virtual:CaptureController()
        Virtual:ClickButton2(Vector2.new())
    end)
end)

--// ══════════════════════════════════════════════════════════════════════════
--// UI - SIMPLE & CLEAN
--// ══════════════════════════════════════════════════════════════════════════

local G = Instance.new("ScreenGui")
G.Name = "FishIt_UI"
G.ResetOnSpawn = false
pcall(function() G.Parent = CoreGui end)
if not G.Parent then G.Parent = Me:WaitForChild("PlayerGui") end

-- Colors
local Colors = {
    bg = Color3.fromRGB(20, 22, 28),
    card = Color3.fromRGB(32, 35, 42),
    accent = Color3.fromRGB(76, 209, 129),
    text = Color3.fromRGB(255, 255, 255),
    dim = Color3.fromRGB(150, 150, 160),
    on = Color3.fromRGB(76, 209, 129),
    off = Color3.fromRGB(220, 80, 80),
}

-- Main Window
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 300, 0, 420)
Main.Position = UDim2.new(0.5, -150, 0.5, -210)
Main.BackgroundColor3 = Colors.bg
Main.BorderSizePixel = 0
Main.Parent = G
Main.Visible = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 16)

-- Shadow
local Shadow = Instance.new("ImageLabel")
Shadow.Size = UDim2.new(1, 30, 1, 30)
Shadow.Position = UDim2.new(0, -15, 0, -15)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://5554236805"
Shadow.ImageColor3 = Color3.new(0, 0, 0)
Shadow.ImageTransparency = 0.6
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(23, 23, 277, 277)
Shadow.ZIndex = -1
Shadow.Parent = Main

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = Colors.accent
Header.BorderSizePixel = 0
Header.Parent = Main

local HeaderCorner = Instance.new("UICorner", Header)
HeaderCorner.CornerRadius = UDim.new(0, 16)

-- Fix bottom corners of header
local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 16)
HeaderFix.Position = UDim2.new(0, 0, 1, -16)
HeaderFix.BackgroundColor3 = Colors.accent
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 1, 0)
Title.Position = UDim2.new(0, 15, 0, 0)
Title.BackgroundTransparency = 1
Title.Text = "🎣 Fish It Auto"
Title.TextColor3 = Colors.text
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

-- Close button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Colors.text
CloseBtn.TextSize = 14
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 8)
CloseBtn.MouseButton1Click:Connect(function() Main.Visible = false end)

-- Content Scroll
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size = UDim2.new(1, -20, 1, -60)
Scroll.Position = UDim2.new(0, 10, 0, 55)
Scroll.BackgroundTransparency = 1
Scroll.ScrollBarThickness = 3
Scroll.ScrollBarImageColor3 = Colors.accent
Scroll.CanvasSize = UDim2.new(0, 0, 0, 750)
Scroll.Parent = Main

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 8)
Layout.Parent = Scroll

--// UI COMPONENTS

local function MakeSection(text)
    local s = Instance.new("TextLabel")
    s.Size = UDim2.new(1, 0, 0, 25)
    s.BackgroundTransparency = 1
    s.Text = "── " .. text .. " ──"
    s.TextColor3 = Colors.accent
    s.TextSize = 13
    s.Font = Enum.Font.GothamBold
    s.Parent = Scroll
end

local function MakeToggle(text, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 45)
    f.BackgroundColor3 = Colors.card
    f.BorderSizePixel = 0
    f.Parent = Scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.65, 0, 1, 0)
    l.Position = UDim2.new(0, 15, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Colors.text
    l.TextSize = 14
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 28)
    btn.Position = UDim2.new(1, -75, 0.5, -14)
    btn.BackgroundColor3 = default and Colors.on or Colors.off
    btn.Text = default and "ON" or "OFF"
    btn.TextColor3 = Colors.text
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.Parent = f
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    local state = default
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Colors.on or Colors.off
        btn.Text = state and "ON" or "OFF"
        callback(state)
    end)
    
    return function(v)
        state = v
        btn.BackgroundColor3 = v and Colors.on or Colors.off
        btn.Text = v and "ON" or "OFF"
    end
end

local function MakeButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 40)
    btn.BackgroundColor3 = Colors.card
    btn.Text = text
    btn.TextColor3 = Colors.text
    btn.TextSize = 14
    btn.Font = Enum.Font.Gotham
    btn.Parent = Scroll
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 10)
    btn.MouseButton1Click:Connect(callback)
end

local function MakeChoice(text, options, default, callback)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 45)
    f.BackgroundColor3 = Colors.card
    f.BorderSizePixel = 0
    f.Parent = Scroll
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
    
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0.45, 0, 1, 0)
    l.Position = UDim2.new(0, 15, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Colors.text
    l.TextSize = 13
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    
    local idx = 1
    for i, v in ipairs(options) do
        if v == default then idx = i break end
    end
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, -20, 0, 28)
    btn.Position = UDim2.new(0.5, 5, 0.5, -14)
    btn.BackgroundColor3 = Colors.accent
    btn.Text = options[idx]
    btn.TextColor3 = Colors.text
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.TextTruncate = Enum.TextTruncate.AtEnd
    btn.Parent = f
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    
    btn.MouseButton1Click:Connect(function()
        idx = idx % #options + 1
        btn.Text = options[idx]
        callback(options[idx])
    end)
end

--// BUILD UI

MakeSection("🎣 FISHING")

MakeChoice("Speed", {"Normal", "Fast", "Super Fast"}, "Super Fast", function(v)
    Setting.Speed = v
end)

MakeChoice("Max Fish", {"3", "5", "7", "9"}, "9", function(v)
    Setting.MaxFish = tonumber(v)
end)

MakeToggle("🎣 START FISHING", false, function(v)
    if v then StartFishing() else StopFishing() end
end)

MakeButton("🔧 Fix Stuck", function()
    pcall(function() Remote.Done:FireServer() end)
    pcall(function() Remote.Reset:InvokeServer() end)
end)

MakeSection("⚡ AUTO")

MakeToggle("Auto Sell", false, function(v)
    Status.AutoSell = v
end)

MakeChoice("Sell Every", {"30 sec", "60 sec", "120 sec"}, "60 sec", function(v)
    Setting.SellTimer = tonumber(v:match("%d+"))
end)

MakeButton("💰 Sell Now", function()
    pcall(function() Remote.Sell:InvokeServer() end)
end)

MakeToggle("Auto Favorite", false, function(v)
    Status.AutoFav = v
end)

MakeChoice("Favorite", {"Mythic+", "Legendary+", "Epic+", "All"}, "Mythic+", function(v)
    if v == "Mythic+" then Setting.FavRarity = 6
    elseif v == "Legendary+" then Setting.FavRarity = 5
    elseif v == "Epic+" then Setting.FavRarity = 4
    else Setting.FavRarity = 1 end
end)

MakeSection("📍 TELEPORT")

local selectedSpot = SpotNames[1]
MakeChoice("Location", SpotNames, SpotNames[1], function(v)
    selectedSpot = v
end)

MakeButton("🚀 Go There!", function()
    if Spots[selectedSpot] then
        GoTo(Spots[selectedSpot])
    end
end)

MakeSection("⚙️ SETTINGS")

MakeButton("⚡ FPS Boost ON", function()
    pcall(function()
        settings().Rendering.QualityLevel = 1
        Light.GlobalShadows = false
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
end)

MakeButton("🔄 Server Hop", function()
    local TPS = game:GetService("TeleportService")
    local url = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
    local data = Http:JSONDecode(game:HttpGet(url))
    if data.data and data.data[1] then
        TPS:TeleportToPlaceInstance(game.PlaceId, data.data[1].id, Me)
    end
end)

MakeButton("🔄 Rejoin", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, Me)
end)

--// DRAGGABLE WINDOW
local drag, dragStart, startPos

Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        drag = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

Header.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or 
       input.UserInputType == Enum.UserInputType.Touch then
        drag = false
    end
end)

UIS.InputChanged:Connect(function(input)
    if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or 
                 input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                   startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

--// FLOATING BUTTON
local Float = Instance.new("TextButton")
Float.Size = UDim2.new(0, 55, 0, 55)
Float.Position = UDim2.new(0, 15, 0.5, -27)
Float.BackgroundColor3 = Colors.accent
Float.Text = "🎣"
Float.TextSize = 26
Float.Parent = G
Instance.new("UICorner", Float).CornerRadius = UDim.new(1, 0)

Float.MouseButton1Click:Connect(function()
    Main.Visible = not Main.Visible
end)

-- Make float button draggable
local fDrag, fStart, fPos

Float.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch then
        fDrag = true
        fStart = input.Position
        fPos = Float.Position
    end
end)

Float.InputEnded:Connect(function()
    fDrag = false
end)

UIS.InputChanged:Connect(function(input)
    if fDrag and input.UserInputType == Enum.UserInputType.Touch then
        local d = input.Position - fStart
        Float.Position = UDim2.new(fPos.X.Scale, fPos.X.Offset + d.X,
                                    fPos.Y.Scale, fPos.Y.Offset + d.Y)
    end
end)

--// DONE
print([[
╔═══════════════════════════════════════════════════╗
║           🎣 FISH IT AUTO - LOADED!               ║
║     Tap the 🎣 button to open/close menu          ║
╚═══════════════════════════════════════════════════╝
]])
