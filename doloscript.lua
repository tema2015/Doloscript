local Players = game:GetService("Players")
local player = Players.LocalPlayer
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local Workspace = game:GetService("Workspace")
local Camera = workspace.CurrentCamera

-- Настройки
local espEnabled = false
local speedEnabled = false
local flyEnabled = false
local hitboxEnabled = false
local thirdPersonEnabled = false
local currentSpeed = 16
local currentFlySpeed = 50
local maxDistance = 1000
local debounce = false

-- Таблицы для хранения объектов
local highlights = {}
local nameTags = {}
local espConnections = {}
local speedConnection = nil
local flyConnection = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil
local hitbox = nil
local hitboxConnection = nil
local thirdPersonConnection = nil

-- ====================== УЛУЧШЕННЫЙ FLY HACK (Кросс-платформенный) ====================== --
local function startFlying()
    if not player.Character then return end
    
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end

    humanoid.PlatformStand = true
    
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyVelocity.P = 1000
    flyBodyVelocity.Parent = rootPart

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyGyro.P = 1000
    flyBodyGyro.D = 50
    flyBodyGyro.CFrame = rootPart.CFrame
    flyBodyGyro.Parent = rootPart

    -- Определяем платформу (ПК или мобильное устройство)
    local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
    
    flyConnection = RunService.Heartbeat:Connect(function()
        if not flyEnabled or not player.Character or not rootPart then return end
        
        flyBodyGyro.CFrame = Camera.CFrame
        
        local direction = Vector3.new()
        
        if isMobile then
            -- Управление для мобильных устройств (адаптивное)
            local touchInputs = UIS:GetTouchInputs()
            for _, touch in ipairs(touchInputs) do
                if touch.Position.X < 0.3 then -- Левая часть экрана
                    direction -= Camera.CFrame.RightVector
                elseif touch.Position.X > 0.7 then -- Правая часть экрана
                    direction += Camera.CFrame.RightVector
                elseif touch.Position.Y < 0.3 then -- Нижняя часть экрана
                    direction -= Camera.CFrame.LookVector
                elseif touch.Position.Y > 0.7 then -- Верхняя часть экрана
                    direction += Camera.CFrame.LookVector
                end
            end
        else
            -- Управление для ПК
            if UIS:IsKeyDown(Enum.KeyCode.W) then direction += Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then direction -= Camera.CFrame.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then direction -= Camera.CFrame.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then direction += Camera.CFrame.RightVector end
        end
        
        -- Вверх/вниз (работает на всех платформах)
        if UIS:IsKeyDown(Enum.KeyCode.Space) or (isMobile and UIS:IsMouseButtonPressed(Enum.UserInputType.Touch)) then
            direction += Vector3.new(0, 1, 0)
        elseif UIS:IsKeyDown(Enum.KeyCode.LeftShift) then
            direction += Vector3.new(0, -1, 0)
        end
        
        if direction.Magnitude > 0 then
            direction = direction.Unit * currentFlySpeed
        end
        
        flyBodyVelocity.Velocity = direction
    end)
end

local function stopFlying()
    if flyConnection then flyConnection:Disconnect() end
    if flyBodyVelocity then flyBodyVelocity:Destroy() end
    if flyBodyGyro then flyBodyGyro:Destroy() end
    
    if player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
    end
end

-- ====================== HITBOX ====================== --
local function createHitbox()
    if hitbox then hitbox:Destroy() end
    
    hitbox = Instance.new("Model")
    hitbox.Name = "PlayerHitbox"
    
    local parts = {
        {Name = "Head", Size = Vector3.new(2, 1, 1), Shape = Enum.PartType.Ball, Color = Color3.new(1, 0, 0)},
        {Name = "Torso", Size = Vector3.new(2, 2, 1), Color = Color3.new(1, 0.3, 0.3)},
        {Name = "LeftArm", Size = Vector3.new(1, 2, 1), Color = Color3.new(1, 0.3, 0.3)},
        {Name = "RightArm", Size = Vector3.new(1, 2, 1), Color = Color3.new(1, 0.3, 0.3)},
        {Name = "LeftLeg", Size = Vector3.new(1, 2, 1), Color = Color3.new(1, 0.3, 0.3)},
        {Name = "RightLeg", Size = Vector3.new(1, 2, 1), Color = Color3.new(1, 0.3, 0.3)}
    }

    for _, partInfo in pairs(parts) do
        local part = Instance.new("Part")
        part.Name = partInfo.Name
        part.Size = partInfo.Size
        if partInfo.Shape then part.Shape = partInfo.Shape end
        part.Color = partInfo.Color
        part.Material = Enum.Material.Neon
        part.CanCollide = false
        part.Anchored = true
        part.Transparency = 0.3
        part.Parent = hitbox
    end

    hitbox.PrimaryPart = hitbox:WaitForChild("Torso")
    hitbox.Parent = Workspace

    hitboxConnection = RunService.Heartbeat:Connect(function()
        if hitboxEnabled and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            hitbox:SetPrimaryPartCFrame(player.Character.HumanoidRootPart.CFrame)
        end
    end)
end

local function removeHitbox()
    if hitbox then hitbox:Destroy() end
    if hitboxConnection then hitboxConnection:Disconnect() end
end

-- ====================== ESP ====================== --
local function updatePlayerESP(otherPlayer)
    if highlights[otherPlayer] then highlights[otherPlayer]:Destroy() end
    if nameTags[otherPlayer] then nameTags[otherPlayer]:Destroy() end

    if not otherPlayer.Character then return end

    local character = otherPlayer.Character
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    local head = character:FindFirstChild("Head")

    if not humanoidRootPart or not head then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight_"..otherPlayer.Name
    highlight.FillColor = Color3.new(1, 0, 0)
    highlight.OutlineColor = Color3.new(1, 0.5, 0.5)
    highlight.FillTransparency = 0.5
    highlight.Parent = character
    highlights[otherPlayer] = highlight

    local nameTag = Instance.new("BillboardGui")
    nameTag.Name = "ESP_NameTag_"..otherPlayer.Name
    nameTag.AlwaysOnTop = true
    nameTag.Size = UDim2.new(0, 200, 0, 50)
    nameTag.StudsOffset = Vector3.new(0, 3, 0)
    nameTag.Adornee = head
    nameTag.MaxDistance = maxDistance
    nameTag.Parent = head

    local textLabel = Instance.new("TextLabel")
    textLabel.Text = otherPlayer.Name
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextSize = 14
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Parent = nameTag
    nameTags[otherPlayer] = nameTag

    espConnections[otherPlayer] = RunService.Heartbeat:Connect(function()
        if not character or not humanoidRootPart or not player.Character then return end
        
        local root = player.Character:FindFirstChild("HumanoidRootPart")
        if not root then return end
        
        local distance = (humanoidRootPart.Position - root.Position).Magnitude
        local isVisible = distance <= maxDistance
        
        highlight.Enabled = isVisible
        nameTag.Enabled = isVisible
        textLabel.Text = isVisible and string.format("%s [%d]", otherPlayer.Name, math.floor(distance)) or ""
    end)
end

local function clearESP()
    for _, highlight in pairs(highlights) do highlight:Destroy() end
    for _, nameTag in pairs(nameTags) do nameTag:Destroy() end
    for _, conn in pairs(espConnections) do conn:Disconnect() end
    highlights = {}
    nameTags = {}
    espConnections = {}
end

local function updateESP()
    clearESP()
    if espEnabled then
        for _, otherPlayer in ipairs(Players:GetPlayers()) do
            if otherPlayer ~= player then
                if otherPlayer.Character then updatePlayerESP(otherPlayer) end
                otherPlayer.CharacterAdded:Connect(function()
                    if espEnabled then updatePlayerESP(otherPlayer) end
                end)
            end
        end
    end
end

-- ====================== SPEED HACK ====================== --
local function updateSpeed()
    if speedEnabled and player.Character then
        local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid.WalkSpeed = currentSpeed end
    end
end

-- ====================== 3RD PERSON ====================== --
local function updateThirdPerson()
    if not player.Character then return end
    
    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    if thirdPersonEnabled then
        Camera.CameraType = Enum.CameraType.Scriptable
        local offset = Vector3.new(0, 3, -8)
        
        thirdPersonConnection = RunService.Heartbeat:Connect(function()
            Camera.CFrame = CFrame.new(humanoidRootPart.Position + offset, humanoidRootPart.Position)
        end)
    else
        if thirdPersonConnection then
            thirdPersonConnection:Disconnect()
            thirdPersonConnection = nil
        end
        Camera.CameraType = Enum.CameraType.Custom
    end
end

-- ====================== REJOIN ====================== --
local function rejoinServer()
    if debounce then return end
    debounce = true
    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
    task.wait(3)
    debounce = false
end

-- ====================== SWORD (Фикс для выдачи в инвентарь) ====================== --
local function giveSword()
    if not player.Character then return end
    
    -- Удаляем старый меч если есть
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        local oldSword = backpack:FindFirstChild("Sword") 
        if oldSword then oldSword:Destroy() end
    end

    -- Создаем новый меч
    local sword = Instance.new("Tool")
    sword.Name = "Sword"
    sword.Grip = CFrame.new(0, -1, 0) * CFrame.Angles(math.pi/2, 0, 0)
    
    -- Создаем рукоять и лезвие
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 1)
    handle.Color = Color3.new(139/255, 69/255, 19/255) -- Коричневый
    handle.Material = Enum.Material.Wood
    handle.Parent = sword
    
    local blade = Instance.new("Part")
    blade.Name = "Blade"
    blade.Size = Vector3.new(0.5, 4, 0.2)
    blade.Color = Color3.new(200/255, 200/255, 200/255) -- Серый
    blade.Material = Enum.Material.Metal
    blade.CFrame = handle.CFrame * CFrame.new(0, -2.5, 0)
    blade.Parent = sword
    
    -- Делаем лезвие острым
    local touchInterest = Instance.new("TouchTransmitter")
    touchInterest.Parent = blade
    
    -- Помещаем в инвентарь (Backpack)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        sword.Parent = backpack
    else
        -- Если инвентаря нет, создаем временный
        sword.Parent = player.Character
    end
end

-- ====================== GUI ====================== --
local function createGUI()
    if player:FindFirstChild("PlayerGui") then
        local oldGui = player.PlayerGui:FindFirstChild("HackMenu")
        if oldGui then oldGui:Destroy() end
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "HackMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local openButton = Instance.new("TextButton")
    openButton.Name = "OpenButton"
    openButton.Size = UDim2.new(0, 120, 0, 50)
    openButton.Position = UDim2.new(0.5, -60, 0.9, -25)
    openButton.Text = "OPEN MENU"
    openButton.BackgroundColor3 = Color3.new(0.2, 0.6, 1)
    openButton.TextColor3 = Color3.new(1, 1, 1)
    openButton.Parent = screenGui

    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 300, 0, 420)
    mainFrame.Position = UDim2.new(0.5, -150, 0.5, -210)
    mainFrame.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
    mainFrame.Visible = false
    mainFrame.Parent = screenGui

    local elements = {
        {Type = "TextLabel", Name = "Title", Text = "HACK MENU", Position = UDim2.new(0.1, 0, 0.03, 0), Size = UDim2.new(0, 280, 0, 30), TextSize = 20, BackgroundTransparency = 1, Font = Enum.Font.SourceSansBold},
        {Type = "TextButton", Name = "ESPToggle", Text = "ESP: OFF", Position = UDim2.new(0.1, 0, 0.1, 0), Size = UDim2.new(0, 280, 0, 35), BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)},
        {Type = "TextButton", Name = "SpeedToggle", Text = "SPEED: OFF", Position = UDim2.new(0.1, 0, 0.2, 0), Size = UDim2.new(0, 280, 0, 35), BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)},
        {Type = "TextBox", Name = "SpeedBox", Text = "16", PlaceholderText = "Speed value", Position = UDim2.new(0.1, 0, 0.3, 0), Size = UDim2.new(0, 280, 0, 30), BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)},
        {Type = "TextButton", Name = "FlyToggle", Text = "FLY: OFF", Position = UDim2.new(0.1, 0, 0.4, 0), Size = UDim2.new(0, 280, 0, 35), BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)},
        {Type = "TextButton", Name = "HitboxToggle", Text = "HITBOX: OFF", Position = UDim2.new(0.1, 0, 0.5, 0), Size = UDim2.new(0, 280, 0, 35), BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)},
        {Type = "TextButton", Name = "ThirdPersonToggle", Text = "3RD PERSON: OFF", Position = UDim2.new(0.1, 0, 0.6, 0), Size = UDim2.new(0, 280, 0, 35), BackgroundColor3 = Color3.new(0.8, 0.2, 0.2)},
        {Type = "TextButton", Name = "SwordButton", Text = "GET SWORD", Position = UDim2.new(0.1, 0, 0.7, 0), Size = UDim2.new(0, 280, 0, 35), BackgroundColor3 = Color3.new(0.5, 0.2, 0)},
        {Type = "TextButton", Name = "RejoinButton", Text = "REJOIN SERVER", Position = UDim2.new(0.1, 0, 0.8, 0), Size = UDim2.new(0, 280, 0, 35), BackgroundColor3 = Color3.new(0.8, 0.4, 0)},
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

    mainFrame:FindFirstChild("HitboxToggle").MouseButton1Click:Connect(function()
        hitboxEnabled = not hitboxEnabled
        local button = mainFrame:FindFirstChild("HitboxToggle")
        button.Text = hitboxEnabled and "HITBOX: ON" or "HITBOX: OFF"
        button.BackgroundColor3 = hitboxEnabled and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.8, 0.2, 0.2)
        if hitboxEnabled then
            createHitbox()
        else
            removeHitbox()
        end
    end)

    mainFrame:FindFirstChild("ThirdPersonToggle").MouseButton1Click:Connect(function()
        thirdPersonEnabled = not thirdPersonEnabled
        local button = mainFrame:FindFirstChild("ThirdPersonToggle")
        button.Text = thirdPersonEnabled and "3RD PERSON: ON" or "3RD PERSON: OFF"
        button.BackgroundColor3 = thirdPersonEnabled and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.8, 0.2, 0.2)
        updateThirdPerson()
    end)

    mainFrame:FindFirstChild("SwordButton").MouseButton1Click:Connect(giveSword)

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

    UIS.InputBegan:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.Escape and mainFrame.Visible then
            mainFrame.Visible = false
            openButton.Visible = true
        end
    end)
end

-- ====================== ИНИЦИАЛИЗАЦИЯ ====================== --
player.CharacterAdded:Connect(function()
    createGUI()
    if speedEnabled then 
        updateSpeed()
        speedConnection = RunService.Heartbeat:Connect(updateSpeed)
    end
    if flyEnabled then startFlying() end
    if espEnabled then updateESP() end
    if hitboxEnabled then createHitbox() end
    if thirdPersonEnabled then updateThirdPerson() end
end)

createGUI()
