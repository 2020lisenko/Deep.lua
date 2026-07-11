local Player = {}

function Player:Initialize(Tab)
    print("Player module initializing...")
    
    -- Сервисы
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    
    -- Настройки
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
    
    -- Коннекты
    local FlyConnection = nil
    local LoopConnection = nil
    local InfJumpConnection = nil
    
    -- Создаем UI
    local Movement = Tab:AddLeftGroupbox("Movement")
    local Fly = Tab:AddRightGroupbox("Fly")
    local Other = Tab:AddLeftGroupbox("Other")
    
    -- Walk Speed
    Movement:AddToggle("CustomWalkSpeed", {
        Text = "Custom Walk Speed",
        Default = false,
        Callback = function(v) 
            Settings.CustomWalkSpeed = v
            if v then
                if LocalPlayer.Character then
                    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.WalkSpeed = Settings.WalkSpeed end
                end
            else
                if LocalPlayer.Character then
                    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.WalkSpeed = 16 end
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
            Settings.WalkSpeed = v
            if Settings.CustomWalkSpeed and LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = v end
            end
        end
    })
    
    -- Loop Speed
    Movement:AddToggle("LoopSpeed", {
        Text = "Loop Speed",
        Default = false,
        Tooltip = "Forces walk speed every frame",
        Callback = function(v) 
            Settings.LoopSpeed = v
            if v then
                if not LoopConnection then
                    LoopConnection = RunService.Heartbeat:Connect(function()
                        if Settings.LoopSpeed and LocalPlayer.Character then
                            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                            if hum then hum.WalkSpeed = Settings.WalkSpeed end
                        end
                        if Settings.LoopJump and LocalPlayer.Character then
                            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                            if hum then hum.JumpPower = Settings.JumpPower end
                        end
                    end)
                end
            else
                if LoopConnection and not Settings.LoopJump then
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
                if LocalPlayer.Character then
                    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.JumpPower = Settings.JumpPower end
                end
            else
                if LocalPlayer.Character then
                    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.JumpPower = 50 end
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
            Settings.JumpPower = v
            if Settings.CustomJumpPower and LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.JumpPower = v end
            end
        end
    })
    
    -- Loop Jump
    Movement:AddToggle("LoopJump", {
        Text = "Loop Jump",
        Default = false,
        Tooltip = "Forces jump power every frame",
        Callback = function(v) 
            Settings.LoopJump = v
            if v then
                if not LoopConnection then
                    LoopConnection = RunService.Heartbeat:Connect(function()
                        if Settings.LoopSpeed and LocalPlayer.Character then
                            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                            if hum then hum.WalkSpeed = Settings.WalkSpeed end
                        end
                        if Settings.LoopJump and LocalPlayer.Character then
                            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                            if hum then hum.JumpPower = Settings.JumpPower end
                        end
                    end)
                end
            else
                if LoopConnection and not Settings.LoopSpeed then
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
                if not InfJumpConnection then
                    InfJumpConnection = UserInputService.JumpRequest:Connect(function()
                        if Settings.InfJump and LocalPlayer.Character then
                            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                            end
                        end
                    end)
                end
            else
                if InfJumpConnection then
                    InfJumpConnection:Disconnect()
                    InfJumpConnection = nil
                end
            end
        end
    })
    
    -- Fly
    Fly:AddToggle("FlyEnabled", {
        Text = "Fly",
        Default = false,
        Callback = function(v) 
            Settings.FlyEnabled = v
            if v then
                -- Start Fly
                if FlyConnection then return end
                
                local character = LocalPlayer.Character
                if not character then return end
                
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if not humanoid or not rootPart then return end
                
                humanoid.PlatformStand = true
                
                local bodyGyro = Instance.new("BodyGyro")
                bodyGyro.Name = "FlyGyro"
                bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
                bodyGyro.P = 30000
                bodyGyro.CFrame = rootPart.CFrame
                bodyGyro.Parent = rootPart
                
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.Name = "FlyVelocity"
                bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyVelocity.Parent = rootPart
                
                FlyConnection = RunService.Heartbeat:Connect(function()
                    if not Settings.FlyEnabled then
                        -- Stop Fly
                        if FlyConnection then
                            FlyConnection:Disconnect()
                            FlyConnection = nil
                        end
                        if LocalPlayer.Character then
                            local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                            if hum then hum.PlatformStand = false end
                            local rp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            if rp then
                                for _, c in ipairs(rp:GetChildren()) do
                                    if c.Name == "FlyGyro" or c.Name == "FlyVelocity" then
                                        c:Destroy()
                                    end
                                end
                            end
                        end
                        return
                    end
                    
                    if not rootPart or not rootPart.Parent then return end
                    
                    local speed = Settings.FlySpeed
                    local camera = workspace.CurrentCamera
                    local moveDirection = Vector3.new(0, 0, 0)
                    
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
                        bodyVelocity.Velocity = moveDirection.Unit * speed
                    else
                        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                    end
                    
                    bodyGyro.CFrame = camera.CFrame
                end)
            else
                -- Stop Fly
                if FlyConnection then
                    FlyConnection:Disconnect()
                    FlyConnection = nil
                end
                if LocalPlayer.Character then
                    local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.PlatformStand = false end
                    local rp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if rp then
                        for _, c in ipairs(rp:GetChildren()) do
                            if c.Name == "FlyGyro" or c.Name == "FlyVelocity" then
                                c:Destroy()
                            end
                        end
                    end
                end
            end
        end
    })
    
    Fly:AddSlider("FlySpeed", {
        Text = "Fly Speed",
        Default = 50,
        Min = 1,
        Max = 200,
        Rounding = 0,
        Callback = function(v) 
            Settings.FlySpeed = v
        end
    })
    
    Fly:AddLabel("WASD - Move | Space - Up | Shift - Down")
    
    -- NoClip
    Other:AddToggle("NoClip", {
        Text = "No Clip",
        Default = false,
        Callback = function(v) 
            Settings.NoClip = v
            if LocalPlayer.Character then
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = not v
                    end
                end
            end
        end
    })
    
    print("Player module loaded!")
    
    return {
        Cleanup = function()
            if FlyConnection then FlyConnection:Disconnect() end
            if LoopConnection then LoopConnection:Disconnect() end
            if InfJumpConnection then InfJumpConnection:Disconnect() end
            
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.WalkSpeed = 16
                    hum.JumpPower = 50
                    hum.PlatformStand = false
                end
                for _, part in ipairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            print("Player cleanup!")
        end
    }
end

return Player
