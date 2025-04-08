local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")

-- Настройки
local espEnabled = false
local speedEnabled = false
local flyEnabled = false
local currentSpeed = 16
local currentFlySpeed = 50
local highlights = {}
local speedConnection = nil
local flyConnection = nil

-- Функция создания GUI
local function createGUI()
    -- Удаляем старый GUI
    if player:FindFirstChild("PlayerGui") then
        local oldGui = player.PlayerGui:FindFirstChild("HackMenu")
        if oldGui then oldGui:Destroy() end
    end

    -- Основной GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HackMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    -- Кнопка открытия
    local openButton = Instance.new("TextButton")
    openButton.Name = "OpenButton"
    openButton.Size = UDim2.new(0, 120, 0, 50)
    openButton.Position = UDim2.new(0.5, -60, 0.9, -25)
    openButton.Text = "OPEN MENU"
    openButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
    openButton.TextColor3 = Color3.new(1, 1, 1)
    openButton.Parent = screenGui

    -- Основное меню
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 350)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -175)
    mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    mainFrame.Visible = false
    mainFrame.Parent = screenGui

    -- Элементы меню
    local elements = {
        {Type = "TextLabel", Name = "Title", Text = "HACK MENU", Position = UDim2.new(0.1, 0, 0.03, 0), Size = UDim2.new(0, 280, 0, 30), TextSize = 20, BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold},
        
        {Type = "TextButton", Name = "ESPToggle", Text = "ESP: OFF", Position = UDim2.new(0.1, 0, 0.15, 0), Size = UDim2.new(0, 280, 0, 35), BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)},
        
        {Type = "TextButton", Name = "SpeedToggle", Text = "SPEED: OFF", Position = UDim2.new(0.1, 0, 0.3, 0), Size = UDim2.new(0, 280, 0, 35), BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)},
        
        {Type = "TextBox", Name = "SpeedBox", Text = "16", PlaceholderText = "Speed value", Position = UDim2.new(0.1, 0, 0.45, 0), Size = UDim2.new(0, 280, 0, 30), BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)},
        
        {Type = "TextButton", Name = "FlyToggle", Text = "FLY: OFF", Position = UDim2.new(0.1, 0, 0.6, 0), Size = UDim2.new(0, 280, 0, 35), BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)},
        
        {Type = "TextButton", Name = "RejoinButton", Text = "REJOIN SERVER", Position = UDim2.new(0.1, 0, 0.75, 0), Size = UDim2.new(0, 280, 0, 35), BackgroundColor3 = Color3.new(0.8, 0.4, 0)},
        
        {Type = "TextButton", Name = "CloseButton", Text = "CLOSE", Position = UDim2.new(0.1, 0, 0.9, 0), Size = UDim2.new(0, 280, 0, 35), BackgroundColor3 = Color3.new(0.2, 0.2, 0.8)}
    }

    for _, element in ipairs(elements) do
        local newElement = Instance.new(element.Type)
        for prop, value in pairs(element) do
            if prop ~= "Type" then
                newElement[prop] = value
            end
        end
        newElement.TextColor3 = Color3.new(1, 1, 1)
        newElement.Parent = mainFrame
    end

    -- Логика ESP
    local function highlightPlayer(playerToHighlight)
        if not playerToHighlight.Character then
            playerToHighlight.CharacterAdded:Wait()
        end
        local highlight = Instance.new("Highlight")
        highlight.FillColor = Color3.new(1, 0, 0)
        highlight.OutlineColor = Color3.new(1, 0.5, 0.5)
        highlight.Parent = playerToHighlight.Character
        highlights[playerToHighlight] = highlight

        playerToHighlight.CharacterAdded:Connect(function(newChar)
            if highlights[playerToHighlight] then
                highlights[playerToHighlight].Parent = newChar
            end
        end)
    end

    local function clearHighlights()
        for _, highlight in pairs(highlights) do
            highlight:Destroy()
        end
        highlights = {}
    end

    local function updateESP()
        clearHighlights()
        if espEnabled then
            for _, otherPlayer in ipairs(Players:GetPlayers()) do
                if otherPlayer ~= player then
                    highlightPlayer(otherPlayer)
                end
            end
        end
    end

    -- Логика Speed Hack
    local function updateSpeed()
        if speedEnabled and player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = currentSpeed
            end
        end
    end

    -- Логика Fly Hack
    local function startFlying()
        if not player.Character then return end
        
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        humanoid.PlatformStand = true
        
        local bodyVelocity = Instance.new("BodyVelocity")
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
        bodyVelocity.Parent = player.Character:FindFirstChild("HumanoidRootPart")
        
        flyConnection = RunService.Heartbeat:Connect(function()
            if not player.Character or not flyEnabled then return end
            
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if not root then return end
            
            local cam = Workspace.CurrentCamera
            local direction = cam.CFrame.LookVector
            
            if UIS:IsKeyDown(Enum.KeyCode.W) then
                bodyVelocity.Velocity = direction * currentFlySpeed
            elseif UIS:IsKeyDown(Enum.KeyCode.S) then
                bodyVelocity.Velocity = -direction * currentFlySpeed
            else
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
        end)
    end

    local function stopFlying()
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        
        if player.Character then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.PlatformStand = false
            end
            
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local bodyVelocity = root:FindFirstChildOfClass("BodyVelocity")
                if bodyVelocity then
                    bodyVelocity:Destroy()
                end
            end
        end
    end

    -- Логика Rejoin
    local function rejoinServer()
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    end

    -- Обработчики кнопок
    openButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = true
        openButton.Visible = false
    end)

    mainFrame:FindFirstChild("CloseButton").MouseButton1Click:Connect(function()
        mainFrame.Visible = false
        openButton.Visible = true
    end)

    mainFrame:FindFirstChild("ESPToggle").MouseButton1Click:Connect(function()
        espEnabled = not espEnabled
        local button = mainFrame:FindFirstChild("ESPToggle")
        button.Text = espEnabled and "ESP: ON" or "ESP: OFF"
        button.BackgroundColor3 = espEnabled and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.8, 0.2, 0.2)
        updateESP()
    end)

    mainFrame:FindFirstChild("SpeedToggle").MouseButton1Click:Connect(function()
        speedEnabled = not speedEnabled
        local button = mainFrame:FindFirstChild("SpeedToggle")
        button.Text = speedEnabled and "SPEED: ON" or "SPEED: OFF"
        button.BackgroundColor3 = speedEnabled and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.8, 0.2, 0.2)
        if speedEnabled then
            updateSpeed()
            speedConnection = RunService.Heartbeat:Connect(updateSpeed)
        elseif speedConnection then
            speedConnection:Disconnect()
            speedConnection = nil
        end
    end)

    mainFrame:FindFirstChild("FlyToggle").MouseButton1Click:Connect(function()
        flyEnabled = not flyEnabled
        local button = mainFrame:FindFirstChild("FlyToggle")
        button.Text = flyEnabled and "FLY: ON" or "FLY: OFF"
        button.BackgroundColor3 = flyEnabled and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.8, 0.2, 0.2)
        if flyEnabled then
            startFlying()
        else
            stopFlying()
        end
    end)

    mainFrame:FindFirstChild("SpeedBox"):GetPropertyChangedSignal("Text"):Connect(function()
        local num = tonumber(mainFrame:FindFirstChild("SpeedBox").Text)
        if num then
            currentSpeed = num
            if speedEnabled then
                updateSpeed()
            end
        end
    end)

    mainFrame:FindFirstChild("RejoinButton").MouseButton1Click:Connect(rejoinServer)

    -- Закрытие по Esc
    UIS.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.Escape and mainFrame.Visible then
            mainFrame.Visible = false
            openButton.Visible = true
        end
    end)
end

-- Обработчик возрождения
player.CharacterAdded:Connect(function()
    createGUI()
    
    -- Восстановление состояний
    if speedEnabled then
        updateSpeed()
        speedConnection = RunService.Heartbeat:Connect(updateSpeed)
    end
    
    if flyEnabled then
        startFlying()
    end
    
    if espEnabled then
        updateESP()
    end
end)

-- Первое создание GUI
createGUI()
