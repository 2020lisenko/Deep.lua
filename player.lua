local Player = {}

function Player:Initialize(Tab)
    print("Player module loading...")
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    
    local Settings = {
        CustomWalkSpeed = false,
        WalkSpeed = 16,
        CustomJumpPower = false,
        JumpPower = 50,
        LoopSpeed = false,
        LoopJump = false,
        InfJump = false,
        FlyEnabled = false,
        FlySpeed = 50,
        NoClip = false
    }
    
    -- Функция для получения текущего персонажа
    local function getCharacter()
        return LocalPlayer.Character
    end
    
    -- Функция для получения Humanoid
    local function getHumanoid()
        local char = getCharacter()
        if char then
            return char:FindFirstChild("Humanoid")
        end
        return nil
    end
    
    -- Функция для получения HumanoidRootPart
    local function getHRP()
        local char = getCharacter()
        if char then
            return char:FindFirstChild("HumanoidRootPart")
        end
        return nil
    end
    
    local flyBodyGyro = nil
    local flyBodyVelocity = nil
    local FlyConnection = nil
    local LoopSpeedConnection = nil
    local LoopJumpConnection = nil
    local InfJumpConnection = nil
    local NoclipConnection = nil
    
    local Movement = Tab:AddLeftGroupbox("Movement")
    local FlyGroup = Tab:AddRightGroupbox("Fly")
    local Other = Tab:AddLeftGroupbox("Other")
    
    -- Применить WalkSpeed
    local function applyWalkSpeed()
        local hum = getHumanoid()
        if hum then
            if Settings.CustomWalkSpeed then
                hum.WalkSpeed = Settings.WalkSpeed
            else
                hum.WalkSpeed = 16
            end
        end
    end
    
    -- Применить JumpPower
    local function applyJumpPower()
        local hum = getHumanoid()
        if hum then
            if Settings.CustomJumpPower then
                hum.JumpPower = Settings.JumpPower
            else
                hum.JumpPower = 50
            end
        end
    end
    
    -- Custom WalkSpeed Toggle
    Movement:AddToggle("CustomWalkSpeed", {
        Text = "Custom Walk Speed",
        Default = false,
        Callback = function(v) 
            Settings.CustomWalkSpeed = v
            applyWalkSpeed()
        end
    })
    
    -- WalkSpeed Slider
    Movement:AddSlider("WalkSpeed", {
        Text = "Walk Speed",
        Default = 16,
        Min = 1,
        Max = 200,
        Rounding = 0,
        Callback = function(v) 
            Settings.WalkSpeed = v
            if Settings.CustomWalkSpeed then
                applyWalkSpeed()
            end
        end
    })
    
    -- Loop Speed
    Movement:AddToggle("LoopSpeed", {
        Text = "Loop Speed",
        Default = false,
        Callback = function(v) 
            Settings.LoopSpeed = v
            if LoopSpeedConnection then
                LoopSpeedConnection:Disconnect()
                LoopSpeedConnection = nil
            end
            if v then
                LoopSpeedConnection = RunService.RenderStepped:Connect(function()
                    local hum = getHumanoid()
                    if hum then
                        hum.WalkSpeed = Settings.WalkSpeed
                    end
                end)
            end
        end
    })
    
    -- Custom JumpPower Toggle
    Movement:AddToggle("CustomJumpPower", {
        Text = "Custom Jump Power",
        Default = false,
        Callback = function(v) 
            Settings.CustomJumpPower = v
            applyJumpPower()
        end
    })
    
    -- JumpPower Slider
    Movement:AddSlider("JumpPower", {
        Text = "Jump Power",
        Default = 50,
        Min = 1,
        Max = 500,
        Rounding = 0,
        Callback = function(v) 
            Settings.JumpPower = v
            if Settings.CustomJumpPower then
                applyJumpPower()
            end
        end
    })
    
    -- Loop Jump
    Movement:AddToggle("LoopJump", {
        Text = "Loop Jump",
        Default = false,
        Callback = function(v) 
            Settings.LoopJump = v
            if LoopJumpConnection then
                LoopJumpConnection:Disconnect()
                LoopJumpConnection = nil
            end
            if v then
                LoopJumpConnection = RunService.RenderStepped:Connect(function()
                    local hum = getHumanoid()
                    if hum then
                        hum.JumpPower = Settings.JumpPower
                    end
                end)
            end
        end
    })
    
    -- Infinite Jump
    Movement:AddToggle("InfJump", {
        Text = "Infinite Jump",
        Default = false,
        Callback = function(v) 
            Settings.InfJump = v
            if InfJumpConnection then
                InfJumpConnection:Disconnect()
                InfJumpConnection = nil
            end
            if v then
                InfJumpConnection = UserInputService.JumpRequest:Connect(function()
                    local hum = getHumanoid()
                    if hum then
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            end
        end
    })
    
    -- Fly
    local function stopFly()
        if FlyConnection then
            FlyConnection:Disconnect()
            FlyConnection = nil
        end
        if flyBodyGyro then
            flyBodyGyro:Destroy()
            flyBodyGyro = nil
        end
        if flyBodyVelocity then
            flyBodyVelocity:Destroy()
            flyBodyVelocity = nil
        end
    end
    
    local function startFly()
        local hrp = getHRP()
        if not hrp then return end
        
        stopFly()
        
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.P = 9e4
        flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBodyGyro.CFrame = hrp.CFrame
        flyBodyGyro.Parent = hrp
        
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBodyVelocity.Parent = hrp
        
        FlyConnection = RunService.RenderStepped:Connect(function()
            local hrp = getHRP()
            local hum = getHumanoid()
            if not hrp or not hum then return end
            
            -- Обновляем родителя если нужно
            if flyBodyGyro and flyBodyGyro.Parent ~= hrp then
                flyBodyGyro.Parent = hrp
            end
            if flyBodyVelocity and flyBodyVelocity.Parent ~= hrp then
                flyBodyVelocity.Parent = hrp
            end
            
            hum.PlatformStand = true
            
            local camera = workspace.CurrentCamera
            local moveDirection = Vector3.new()
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection += camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection -= camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection -= camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection += camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection += Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDirection -= Vector3.new(0, 1, 0)
            end
            
            if moveDirection.Magnitude > 0 then
                flyBodyVelocity.Velocity = moveDirection.Unit * Settings.FlySpeed
            else
                flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
            
            flyBodyGyro.CFrame = camera.CFrame
        end)
    end
    
    FlyGroup:AddToggle("FlyEnabled", {
        Text = "Fly",
        Default = false,
        Callback = function(v) 
            Settings.FlyEnabled = v
            if v then
                startFly()
            else
                stopFly()
                -- Убираем PlatformStand
                local hum = getHumanoid()
                if hum then
                    hum.PlatformStand = false
                end
            end
        end
    })
    
    FlyGroup:AddSlider("FlySpeed", {
        Text = "Fly Speed",
        Default = 50,
        Min = 1,
        Max = 200,
        Rounding = 0,
        Callback = function(v) 
            Settings.FlySpeed = v
        end
    })
    
    -- NoClip
    Other:AddToggle("NoClip", {
        Text = "No Clip",
        Default = false,
        Callback = function(v) 
            Settings.NoClip = v
            if NoclipConnection then
                NoclipConnection:Disconnect()
                NoclipConnection = nil
            end
            if v then
                NoclipConnection = RunService.RenderStepped:Connect(function()
                    local char = getCharacter()
                    if char then
                        for _, part in pairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            else
                local char = getCharacter()
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = true
                        end
                    end
                end
            end
        end
    })
    
    -- Обработчик респавна
    local characterAddedConnection
    characterAddedConnection = LocalPlayer.CharacterAdded:Connect(function(char)
        -- Ждём загрузки персонажа
        char:WaitForChild("Humanoid")
        char:WaitForChild("HumanoidRootPart")
        
        -- Применяем настройки
        applyWalkSpeed()
        applyJumpPower()
        
        -- Если fly был включен, перезапускаем
        if Settings.FlyEnabled then
            startFly()
        end
    end)
    
    print("Player module loaded!")
    
    return {
        Cleanup = function()
            print("Player cleanup!")
            stopFly()
            if LoopSpeedConnection then LoopSpeedConnection:Disconnect() end
            if LoopJumpConnection then LoopJumpConnection:Disconnect() end
            if InfJumpConnection then InfJumpConnection:Disconnect() end
            if NoclipConnection then NoclipConnection:Disconnect() end
            if characterAddedConnection then characterAddedConnection:Disconnect() end
            
            -- Сбрасываем всё
            local hum = getHumanoid()
            if hum then
                hum.WalkSpeed = 16
                hum.JumpPower = 50
                hum.PlatformStand = false
            end
        end
    }
end

return Player
