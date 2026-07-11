local Player = {}

function Player:Initialize(Tab)
    print("Player module loading...")
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    local Movement = Tab:AddLeftGroupbox("Movement")
    
    -- WalkSpeed
    local WalkSpeedSlider = Movement:AddSlider("WalkSpeed", {
        Text = "Walk Speed",
        Default = 16,
        Min = 1,
        Max = 200,
        Rounding = 0,
        Callback = function(v)
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum.WalkSpeed = v
                    print("WalkSpeed set to:", v)
                end
            end
        end
    })
    
    -- JumpHeight
    local JumpHeightSlider = Movement:AddSlider("JumpHeight", {
        Text = "Jump Height",
        Default = 7.2,
        Min = 1,
        Max = 50,
        Rounding = 1,
        Callback = function(v)
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum.JumpHeight = v
                    print("JumpHeight set to:", v)
                end
            end
        end
    })
    
    local Character = Tab:AddLeftGroupbox("Character")
    
    -- Fly
    local flyConnection
    local flyEnabled = false
    local bodyGyro
    local bodyVelocity
    
    Character:AddToggle("Fly", {
        Text = "Fly",
        Default = false,
        Callback = function(v)
            flyEnabled = v
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChild("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if not hum or not root then return end
            
            if flyEnabled then
                if flyConnection then flyConnection:Disconnect() end
                
                -- Сохраняем ссылки на созданные объекты
                bodyGyro = Instance.new("BodyGyro")
                bodyGyro.P = 9e4
                bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bodyGyro.Parent = root
                
                bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bodyVelocity.Parent = root
                
                flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
                    if not flyEnabled or not char or not char.Parent or not root or not root.Parent then 
                        -- Автоматически выключаем полет если персонаж исчез
                        flyEnabled = false
                        if flyConnection then
                            flyConnection:Disconnect()
                            flyConnection = nil
                        end
                        if bodyGyro then
                            bodyGyro:Destroy()
                            bodyGyro = nil
                        end
                        if bodyVelocity then
                            bodyVelocity:Destroy()
                            bodyVelocity = nil
                        end
                        return 
                    end
                    
                    if bodyGyro and bodyGyro.Parent then
                        bodyGyro.CFrame = workspace.CurrentCamera.CFrame
                    end
                    
                    local velocity = Vector3.zero
                    if hum.MoveDirection.Magnitude > 0 then
                        velocity = hum.MoveDirection * 50
                    end
                    
                    -- Проверяем нажатие пробела для полета вверх
                    if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
                        velocity = velocity + Vector3.new(0, 50, 0)
                    end
                    
                    if bodyVelocity and bodyVelocity.Parent then
                        bodyVelocity.Velocity = velocity
                    end
                end)
                print("Fly enabled")
            else
                if flyConnection then
                    flyConnection:Disconnect()
                    flyConnection = nil
                end
                if bodyGyro then
                    bodyGyro:Destroy()
                    bodyGyro = nil
                end
                if bodyVelocity then
                    bodyVelocity:Destroy()
                    bodyVelocity = nil
                end
                print("Fly disabled")
            end
        end
    })
    
    -- Noclip
    local noclipConnection
    local noclipEnabled = false
    
    Character:AddToggle("Noclip", {
        Text = "Noclip",
        Default = false,
        Callback = function(v)
            noclipEnabled = v
            if noclipEnabled then
                if noclipConnection then noclipConnection:Disconnect() end
                noclipConnection = game:GetService("RunService").Stepped:Connect(function()
                    if noclipEnabled and LocalPlayer.Character then
                        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
                print("Noclip enabled")
            else
                if noclipConnection then
                    noclipConnection:Disconnect()
                    noclipConnection = nil
                end
                if LocalPlayer.Character then
                    for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = true
                        end
                    end
                end
                print("Noclip disabled")
            end
        end
    })
    
    -- Infinite Jump
    local infJumpEnabled = false
    local infJumpConnection
    
    Character:AddToggle("InfiniteJump", {
        Text = "Infinite Jump",
        Default = false,
        Callback = function(v)
            infJumpEnabled = v
            if infJumpEnabled then
                if infJumpConnection then infJumpConnection:Disconnect() end
                infJumpConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if infJumpEnabled and input.KeyCode == Enum.KeyCode.Space then
                        local char = LocalPlayer.Character
                        if char then
                            local hum = char:FindFirstChild("Humanoid")
                            if hum then
                                hum:ChangeState(Enum.HumanoidStateType.Jumping)
                            end
                        end
                    end
                end)
                print("Infinite Jump enabled")
            else
                if infJumpConnection then
                    infJumpConnection:Disconnect()
                    infJumpConnection = nil
                end
                print("Infinite Jump disabled")
            end
        end
    })
    
    -- Reset
    Movement:AddButton("Reset Movement", function()
        WalkSpeedSlider:SetValue(16)
        JumpHeightSlider:SetValue(7.2)
        
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = 16
                hum.JumpHeight = 7.2
            end
        end
        print("Movement reset")
    end)
    
    print("Player module loaded!")
    
    return {
        Cleanup = function()
            if flyConnection then 
                flyConnection:Disconnect() 
                flyConnection = nil
            end
            if bodyGyro then
                bodyGyro:Destroy()
                bodyGyro = nil
            end
            if bodyVelocity then
                bodyVelocity:Destroy()
                bodyVelocity = nil
            end
            if noclipConnection then 
                noclipConnection:Disconnect()
                noclipConnection = nil
            end
            if infJumpConnection then 
                infJumpConnection:Disconnect()
                infJumpConnection = nil
            end
            if LocalPlayer.Character then
                local root = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local bg = root:FindFirstChild("BodyGyro")
                    local bv = root:FindFirstChild("BodyVelocity")
                    if bg then bg:Destroy() end
                    if bv then bv:Destroy() end
                end
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
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
