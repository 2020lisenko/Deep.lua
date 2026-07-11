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
    
    local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local Humanoid = Character:WaitForChild("Humanoid")
    local HRP = Character:WaitForChild("HumanoidRootPart")
    
    local FlyConnection = nil
    local LoopConnection = nil
    local InfJumpConnection = nil
    
    -- Обновление персонажа при респавне
    LocalPlayer.CharacterAdded:Connect(function(char)
        Character = char
        Humanoid = char:WaitForChild("Humanoid")
        HRP = char:WaitForChild("HumanoidRootPart")
        
        -- Применить настройки заново
        if Settings.CustomWalkSpeed then
            Humanoid.WalkSpeed = Settings.WalkSpeed
        end
        if Settings.CustomJumpPower then
            Humanoid.JumpPower = Settings.JumpPower
        end
    end)
    
    local Movement = Tab:AddLeftGroupbox("Movement")
    local FlyGroup = Tab:AddRightGroupbox("Fly")
    local Other = Tab:AddLeftGroupbox("Other")
    
    -- Walk Speed
    Movement:AddToggle("CustomWalkSpeed", {
        Text = "Custom Walk Speed",
        Default = false,
        Callback = function(v) 
            Settings.CustomWalkSpeed = v
            if v then
                Humanoid.WalkSpeed = Settings.WalkSpeed
            else
                Humanoid.WalkSpeed = 16
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
            Settings.WalkSpeed = v
            if Settings.CustomWalkSpeed then
                Humanoid.WalkSpeed = v
            end
        end
    })
    
    -- Loop Speed
    Movement:AddToggle("LoopSpeed", {
        Text = "Loop Speed",
        Default = false,
        Callback = function(v) 
            Settings.LoopSpeed = v
            if v then
                LoopConnection = RunService.Heartbeat:Connect(function()
                    if Humanoid and HRP then
                        Humanoid.WalkSpeed = Settings.WalkSpeed
                    end
                end)
            else
                if LoopConnection then
                    LoopConnection:Disconnect()
                    LoopConnection = nil
                end
            end
        end
    })
    
    -- Jump Power
    Movement:AddToggle("CustomJumpPower", {
        Text = "Custom Jump Power",
        Default = false,
        Callback = function(v) 
            Settings.CustomJumpPower = v
            if v then
                Humanoid.JumpPower = Settings.JumpPower
            else
                Humanoid.JumpPower = 50
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
            Settings.JumpPower = v
            if Settings.CustomJumpPower then
                Humanoid.JumpPower = v
            end
        end
    })
    
    -- Loop Jump
    Movement:AddToggle("LoopJump", {
        Text = "Loop Jump",
        Default = false,
        Callback = function(v) 
            Settings.LoopJump = v
            if v then
                LoopConnection = RunService.Heartbeat:Connect(function()
                    if Humanoid and HRP then
                        Humanoid.JumpPower = Settings.JumpPower
                    end
                end)
            else
                if LoopConnection then
                    LoopConnection:Disconnect()
                    LoopConnection = nil
                end
            end
        end
    })
    
    -- Infinite Jump
    Movement:AddToggle("InfJump", {
        Text = "Infinite Jump",
        Default = false,
        Callback = function(v) 
            Settings.InfJump = v
            if v then
                InfJumpConnection = UserInputService.JumpRequest:Connect(function()
                    if Humanoid then
                        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end)
            else
                if InfJumpConnection then
                    InfJumpConnection:Disconnect()
                    InfJumpConnection = nil
                end
            end
        end
    })
    
    -- Fly
    local flyBodyGyro = nil
    local flyBodyVelocity = nil
    
    FlyGroup:AddToggle("FlyEnabled", {
        Text = "Fly",
        Default = false,
        Callback = function(v) 
            Settings.FlyEnabled = v
            if v then
                -- Создаем BodyGyro и BodyVelocity
                flyBodyGyro = Instance.new("BodyGyro")
                flyBodyGyro.P = 9e4
                flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                flyBodyGyro.CFrame = HRP.CFrame
                flyBodyGyro.Parent = HRP
                
                flyBodyVelocity = Instance.new("BodyVelocity")
                flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
                flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                flyBodyVelocity.Parent = HRP
                
                -- Управление полетом
                FlyConnection = RunService.Heartbeat:Connect(function()
                    if not HRP or not Humanoid then return end
                    
                    local moveDirection = Vector3.new()
                    
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        moveDirection += workspace.CurrentCamera.CFrame.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        moveDirection -= workspace.CurrentCamera.CFrame.LookVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        moveDirection -= workspace.CurrentCamera.CFrame.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        moveDirection += workspace.CurrentCamera.CFrame.RightVector
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        moveDirection += Vector3.new(0, 1, 0)
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                        moveDirection -= Vector3.new(0, 1, 0)
                    end
                    
                    if moveDirection.Magnitude > 0 then
                        moveDirection = moveDirection.Unit
                    end
                    
                    flyBodyVelocity.Velocity = moveDirection * Settings.FlySpeed
                    flyBodyGyro.CFrame = workspace.CurrentCamera.CFrame
                end)
            else
                -- Удаляем fly
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
    local noclipConnection = nil
    
    Other:AddToggle("NoClip", {
        Text = "No Clip",
        Default = false,
        Callback = function(v) 
            Settings.NoClip = v
            if v then
                noclipConnection = RunService.Stepped:Connect(function()
                    if Character then
                        for _, part in pairs(Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
            else
                if noclipConnection then
                    noclipConnection:Disconnect()
                    noclipConnection = nil
                end
                -- Восстанавливаем коллизии
                if Character then
                    for _, part in pairs(Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = true
                        end
                    end
                end
            end
        end
    })
    
    print("Player module loaded!")
    
    return {
        Cleanup = function()
            print("Player cleanup!")
            -- Отключаем все соединения
            if FlyConnection then FlyConnection:Disconnect() end
            if LoopConnection then LoopConnection:Disconnect() end
            if InfJumpConnection then InfJumpConnection:Disconnect() end
            if noclipConnection then noclipConnection:Disconnect() end
            if flyBodyGyro then flyBodyGyro:Destroy() end
            if flyBodyVelocity then flyBodyVelocity:Destroy() end
        end
    }
end

return Player
