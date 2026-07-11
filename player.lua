local Player = {}

function Player:Initialize(Tab)
    print("Player module loading...")
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    
    -- Переменные для соединений
    local loopSpeedConnection = nil
    local loopJumpConnection = nil
    local infJumpConnection = nil
    local flyConnection = nil
    local noclipConnection = nil
    local flyBodyGyro = nil
    local flyBodyVelocity = nil
    
    local Movement = Tab:AddLeftGroupbox("Movement")
    local FlyGroup = Tab:AddRightGroupbox("Fly")
    local Other = Tab:AddLeftGroupbox("Other")
    
    -- Custom Walk Speed
    local walkSpeedEnabled = false
    local walkSpeedValue = 16
    
    Movement:AddToggle("CustomWalkSpeed", {
        Text = "Custom Walk Speed",
        Default = false,
        Callback = function(v)
            walkSpeedEnabled = v
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    if v then
                        hum.WalkSpeed = walkSpeedValue
                    else
                        hum.WalkSpeed = 16
                    end
                end
            end
        end
    })
    
    Movement:AddSlider("WalkSpeed", {
        Text = "Walk Speed",
        Default = 16,
        Min = 1,
        Max = 200,
        Rounding = 0,
        Callback = function(v)
            walkSpeedValue = v
            if walkSpeedEnabled then
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    if hum then
                        hum.WalkSpeed = v
                    end
                end
            end
        end
    })
    
    -- Loop Speed
    Movement:AddToggle("LoopSpeed", {
        Text = "Loop Speed",
        Default = false,
        Callback = function(v)
            if loopSpeedConnection then
                loopSpeedConnection:Disconnect()
                loopSpeedConnection = nil
            end
            
            if v then
                loopSpeedConnection = RunService.RenderStepped:Connect(function()
                    local char = LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChild("Humanoid")
                        if hum then
                            hum.WalkSpeed = walkSpeedValue
                        end
                    end
                end)
            end
        end
    })
    
    -- Custom Jump Power
    local jumpPowerEnabled = false
    local jumpPowerValue = 50
    
    Movement:AddToggle("CustomJumpPower", {
        Text = "Custom Jump Power",
        Default = false,
        Callback = function(v)
            jumpPowerEnabled = v
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    if v then
                        hum.JumpPower = jumpPowerValue
                    else
                        hum.JumpPower = 50
                    end
                end
            end
        end
    })
    
    Movement:AddSlider("JumpPower", {
        Text = "Jump Power",
        Default = 50,
        Min = 1,
        Max = 500,
        Rounding = 0,
        Callback = function(v)
            jumpPowerValue = v
            if jumpPowerEnabled then
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    if hum then
                        hum.JumpPower = v
                    end
                end
            end
        end
    })
    
    -- Loop Jump
    Movement:AddToggle("LoopJump", {
        Text = "Loop Jump",
        Default = false,
        Callback = function(v)
            if loopJumpConnection then
                loopJumpConnection:Disconnect()
                loopJumpConnection = nil
            end
            
            if v then
                loopJumpConnection = RunService.RenderStepped:Connect(function()
                    local char = LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChild("Humanoid")
                        if hum then
                            hum.JumpPower = jumpPowerValue
                        end
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
            if infJumpConnection then
                infJumpConnection:Disconnect()
                infJumpConnection = nil
            end
            
            if v then
                infJumpConnection = UserInputService.JumpRequest:Connect(function()
                    local char = LocalPlayer.Character
                    if char then
                        local hum = char:FindFirstChild("Humanoid")
                        if hum then
                            hum:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end
                end)
            end
        end
    })
    
    -- Fly
    local flySpeed = 50
    
    local function startFly()
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        -- Создаём BodyGyro
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.P = 9e4
        flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBodyGyro.CFrame = hrp.CFrame
        flyBodyGyro.Parent = hrp
        
        -- Создаём BodyVelocity
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBodyVelocity.Parent = hrp
        
        -- Запускаем цикл полёта
        flyConnection = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if not hrp or not hum then return end
            
            -- Обновляем родителя если персонаж изменился
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
                moveDirection = moveDirection + camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - camera.CFrame.LookVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + camera.CFrame.RightVector
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = moveDirection + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDirection = moveDirection - Vector3.new(0, 1, 0)
            end
            
            if moveDirection.Magnitude > 0 then
                flyBodyVelocity.Velocity = moveDirection.Unit * flySpeed
            else
                flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            end
            
            flyBodyGyro.CFrame = camera.CFrame
        end)
    end
    
    local function stopFly()
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        if flyBodyGyro then
            flyBodyGyro:Destroy()
            flyBodyGyro = nil
        end
        if flyBodyVelocity then
            flyBodyVelocity:Destroy()
            flyBodyVelocity = nil
        end
        
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.PlatformStand = false
            end
        end
    end
    
    FlyGroup:AddToggle("FlyEnabled", {
        Text = "Fly",
        Default = false,
        Callback = function(v)
            if v then
                startFly()
            else
                stopFly()
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
            flySpeed = v
        end
    })
    
    -- NoClip
    Other:AddToggle("NoClip", {
        Text = "No Clip",
        Default = false,
        Callback = function(v)
            if noclipConnection then
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            
            if v then
                noclipConnection = RunService.RenderStepped:Connect(function()
                    local char = LocalPlayer.Character
                    if char then
                        for _, part in pairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            else
                local char = LocalPlayer.Character
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
    LocalPlayer.CharacterAdded:Connect(function(char)
        char:WaitForChild("Humanoid")
        char:WaitForChild("HumanoidRootPart")
        
        -- Применяем настройки после респавна
        if walkSpeedEnabled then
            char.Humanoid.WalkSpeed = walkSpeedValue
        end
        if jumpPowerEnabled then
            char.Humanoid.JumpPower = jumpPowerValue
        end
    end)
    
    print("Player module loaded!")
    
    return {
        Cleanup = function()
            print("Player cleanup!")
            stopFly()
            if loopSpeedConnection then loopSpeedConnection:Disconnect() end
            if loopJumpConnection then loopJumpConnection:Disconnect() end
            if infJumpConnection then infJumpConnection:Disconnect() end
            if noclipConnection then noclipConnection:Disconnect() end
        end
    }
end

return Player
