--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                  FISH IT - REMOTE SPY                         ║
    ║              With UI for Android/Delta                        ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    HOW TO USE:
    1. Copy this ENTIRE script
    2. Open Delta Executor
    3. Paste and Execute
    4. A UI window will appear
    5. Play the game normally (cast rod, reel, sell fish)
    6. The UI will show all remotes being called
    7. Click "Copy Results" to copy to clipboard
]]

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Storage
local foundRemotes = {}
local logText = ""

-- =====================================================
-- CREATE UI
-- =====================================================
local function createUI()
    -- Destroy old UI if exists
    if PlayerGui:FindFirstChild("RemoteSpyUI") then
        PlayerGui.RemoteSpyUI:Destroy()
    end
    
    -- Main ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "RemoteSpyUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = PlayerGui
    
    -- Main Frame
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 350, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    -- Corner
    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = MainFrame
    
    -- Title Bar
    local TitleBar = Instance.new("Frame")
    TitleBar.Name = "TitleBar"
    TitleBar.Size = UDim2.new(1, 0, 0, 35)
    TitleBar.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    TitleBar.BorderSizePixel = 0
    TitleBar.Parent = MainFrame
    
    local TitleCorner = Instance.new("UICorner")
    TitleCorner.CornerRadius = UDim.new(0, 10)
    TitleCorner.Parent = TitleBar
    
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -40, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🔍 Remote Spy - Fish It"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 16
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TitleBar
    
    -- Close Button
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -32, 0, 2)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
    CloseBtn.Text = "X"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.TextSize = 14
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = TitleBar
    
    local CloseBtnCorner = Instance.new("UICorner")
    CloseBtnCorner.CornerRadius = UDim.new(0, 6)
    CloseBtnCorner.Parent = CloseBtn
    
    -- Scroll Frame for logs
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Name = "ScrollFrame"
    ScrollFrame.Size = UDim2.new(1, -20, 1, -100)
    ScrollFrame.Position = UDim2.new(0, 10, 0, 45)
    ScrollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    ScrollFrame.BorderSizePixel = 0
    ScrollFrame.ScrollBarThickness = 6
    ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 120)
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ScrollFrame.Parent = MainFrame
    
    local ScrollCorner = Instance.new("UICorner")
    ScrollCorner.CornerRadius = UDim.new(0, 6)
    ScrollCorner.Parent = ScrollFrame
    
    -- Log TextLabel
    local LogLabel = Instance.new("TextLabel")
    LogLabel.Name = "LogLabel"
    LogLabel.Size = UDim2.new(1, -10, 1, 0)
    LogLabel.Position = UDim2.new(0, 5, 0, 0)
    LogLabel.BackgroundTransparency = 1
    LogLabel.Text = "Waiting for remote calls...\nPlay the game normally!"
    LogLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    LogLabel.TextSize = 12
    LogLabel.Font = Enum.Font.Code
    LogLabel.TextXAlignment = Enum.TextXAlignment.Left
    LogLabel.TextYAlignment = Enum.TextYAlignment.Top
    LogLabel.TextWrapped = true
    LogLabel.RichText = true
    LogLabel.Parent = ScrollFrame
    
    -- Button Container
    local ButtonContainer = Instance.new("Frame")
    ButtonContainer.Name = "ButtonContainer"
    ButtonContainer.Size = UDim2.new(1, -20, 0, 40)
    ButtonContainer.Position = UDim2.new(0, 10, 1, -50)
    ButtonContainer.BackgroundTransparency = 1
    ButtonContainer.Parent = MainFrame
    
    -- Copy Button
    local CopyBtn = Instance.new("TextButton")
    CopyBtn.Name = "CopyBtn"
    CopyBtn.Size = UDim2.new(0.48, 0, 1, 0)
    CopyBtn.Position = UDim2.new(0, 0, 0, 0)
    CopyBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
    CopyBtn.Text = "📋 Copy Results"
    CopyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CopyBtn.TextSize = 14
    CopyBtn.Font = Enum.Font.GothamBold
    CopyBtn.Parent = ButtonContainer
    
    local CopyBtnCorner = Instance.new("UICorner")
    CopyBtnCorner.CornerRadius = UDim.new(0, 6)
    CopyBtnCorner.Parent = CopyBtn
    
    -- Clear Button
    local ClearBtn = Instance.new("TextButton")
    ClearBtn.Name = "ClearBtn"
    ClearBtn.Size = UDim2.new(0.48, 0, 1, 0)
    ClearBtn.Position = UDim2.new(0.52, 0, 0, 0)
    ClearBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 50)
    ClearBtn.Text = "🗑️ Clear"
    ClearBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    ClearBtn.TextSize = 14
    ClearBtn.Font = Enum.Font.GothamBold
    ClearBtn.Parent = ButtonContainer
    
    local ClearBtnCorner = Instance.new("UICorner")
    ClearBtnCorner.CornerRadius = UDim.new(0, 6)
    ClearBtnCorner.Parent = ClearBtn
    
    -- Make draggable
    local dragging = false
    local dragStart, startPos
    
    TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = MainFrame.Position
        end
    end)
    
    TitleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- Button handlers
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    CopyBtn.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard(logText)
            CopyBtn.Text = "✅ Copied!"
            task.wait(1)
            CopyBtn.Text = "📋 Copy Results"
        else
            CopyBtn.Text = "❌ No clipboard"
            task.wait(1)
            CopyBtn.Text = "📋 Copy Results"
        end
    end)
    
    ClearBtn.MouseButton1Click:Connect(function()
        logText = ""
        foundRemotes = {}
        LogLabel.Text = "Cleared! Waiting for remote calls..."
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    end)
    
    return LogLabel, ScrollFrame
end

-- Create UI
local LogLabel, ScrollFrame = createUI()

-- =====================================================
-- LOG FUNCTION
-- =====================================================
local function addLog(remoteType, remoteName, args)
    -- Format args
    local argsStr = ""
    for i, arg in ipairs(args) do
        local t = type(arg)
        if t == "table" then
            local tableStr = "{"
            local count = 0
            for k, v in pairs(arg) do
                if count < 3 then
                    tableStr = tableStr .. tostring(k) .. "=" .. tostring(v) .. ", "
                end
                count = count + 1
            end
            if count > 3 then
                tableStr = tableStr .. "..."
            end
            argsStr = argsStr .. tableStr .. "}, "
        elseif t == "Instance" then
            argsStr = argsStr .. arg.Name .. ", "
        elseif t == "string" then
            argsStr = argsStr .. '"' .. arg .. '", '
        else
            argsStr = argsStr .. tostring(arg) .. ", "
        end
    end
    
    -- Color based on type
    local color = remoteType == "INVOKE" and "rgb(100,200,255)" or "rgb(255,200,100)"
    
    -- Add to log
    local entry = string.format('<font color="%s">[%s]</font> <font color="rgb(255,255,255)">%s</font>(%s)\n', color, remoteType, remoteName, argsStr)
    logText = logText .. string.format("[%s] %s(%s)\n", remoteType, remoteName, argsStr)
    
    -- Store
    table.insert(foundRemotes, {
        type = remoteType,
        name = remoteName,
        args = args
    })
    
    -- Update UI
    if LogLabel then
        -- Get current text and add new entry
        local currentText = LogLabel.Text
        if currentText:find("Waiting for remote calls") then
            currentText = ""
        end
        LogLabel.Text = currentText .. entry
        
        -- Auto-scroll
        LogLabel.Size = UDim2.new(1, -10, 0, LogLabel.TextBounds.Y + 10)
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, LogLabel.TextBounds.Y + 10)
        ScrollFrame.CanvasPosition = Vector2.new(0, ScrollFrame.CanvasSize.Y.Offset)
    end
end

-- =====================================================
-- HOOK REMOTES
-- =====================================================
local function hookAllRemotes()
    -- Method 1: hookmetamethod (best for Delta)
    if hookmetamethod then
        local oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            local args = {...}
            
            if method == "InvokeServer" then
                addLog("INVOKE", self.Name, args)
            elseif method == "FireServer" then
                addLog("FIRE", self.Name, args)
            end
            
            return oldNamecall(self, ...)
        end)
        
        addLog("INFO", "hookmetamethod", {"installed!"})
        return
    end
    
    -- Method 2: Direct hook (fallback)
    for _, remote in pairs(ReplicatedStorage:GetDescendants()) do
        if remote:IsA("RemoteFunction") then
            local original = remote.InvokeServer
            remote.InvokeServer = function(self, ...)
                addLog("INVOKE", remote.Name, {...})
                return original(self, ...)
            end
        elseif remote:IsA("RemoteEvent") then
            local original = remote.FireServer
            remote.FireServer = function(self, ...)
                addLog("FIRE", remote.Name, {...})
                return original(self, ...)
            end
        end
    end
    
    addLog("INFO", "Direct hooks", {"installed!"})
end

-- =====================================================
-- LIST ALL REMOTES
-- =====================================================
local function listAllRemotes()
    addLog("INFO", "=== ALL REMOTES ===", {})
    
    for _, child in pairs(ReplicatedStorage:GetDescendants()) do
        if child:IsA("RemoteFunction") then
            addLog("LIST", child.Name, {"RemoteFunction"})
        elseif child:IsA("RemoteEvent") then
            addLog("LIST", child.Name, {"RemoteEvent"})
        end
    end
    
    addLog("INFO", "=== END LIST ===", {})
end

-- =====================================================
-- INITIALIZE
-- =====================================================
addLog("INFO", "Remote Spy Started", {})
addLog("INFO", "Play the game normally!", {})
hookAllRemotes()

-- List remotes after 2 seconds
task.delay(2, listAllRemotes)

-- Global commands
_G.SpyCopy = function()
    if setclipboard then
        setclipboard(logText)
        print("Copied to clipboard!")
    else
        print(logText)
    end
end

_G.SpyList = listAllRemotes
