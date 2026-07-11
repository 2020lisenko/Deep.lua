local Player = {}

function Player:Initialize(Tab)
    print("Player module loading...")
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    local Movement = Tab:AddLeftGroupbox("Movement")
    
    -- WalkSpeed
    Movement:AddSlider("WalkSpeed", {
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
    
    -- JumpPower
    Movement:AddSlider("JumpPower", {
        Text = "Jump Power",
        Default = 50,
        Min = 0,
        Max = 500,
        Rounding = 0,
        Callback = function(v)
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum.JumpPower = v
                    print("JumpPower set to:", v)
                end
            end
        end
    })
    
    -- JumpHeight
    Movement:AddSlider("JumpHeight", {
        Text = "Jump Height",
        Default = 7,
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
    
    -- Gravity
    Movement:AddSlider("Gravity", {
        Text = "Gravity",
        Default = 196.2,
        Min = 0,
        Max = 500,
        Rounding = 1,
        Callback = function(v)
            workspace.Gravity = v
            print("Gravity set to:", v)
        end
    })
    
    -- HipHeight
    Movement:AddSlider("HipHeight", {
        Text = "Hip Height",
        Default = 2,
        Min = 0,
        Max = 10,
        Rounding = 1,
        Callback = function(v)
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum.HipHeight = v
                    print("HipHeight set to:", v)
                end
            end
        end
    })
    
    -- Character features
    local Character = Tab:AddLeftGroupbox("Character")
    
    -- Fly toggle
    local flyConnection
    local flyEnabled = false
    
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
                flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
                    if flyEnabled and char and root and hum then
                        hum.PlatformStand = true
                        local moveDir = root.CFrame.LookVector * (hum.MoveDirection.Magnitude > 0 and 1 or 0)
                        root.Velocity = Vector3.new(moveDir.X * 50, math.clamp(root.Velocity.Y, -50, 50), moveDir.Z * 50)
                    end
                end)
                print("Fly enabled")
            else
                if flyConnection then
                    flyConnection:Disconnect()
                    flyConnection = nil
                end
                if hum and char then
                    hum.PlatformStand = false
                end
                print("Fly disabled")
            end
        end
    })
    
    -- Noclip toggle
    local noclipConnection
    local noclipEnabled = false
    
    Character:AddToggle("Noclip", {
        Text = "Noclip",
        Default = false,
        Callback = function(v)
            noclipEnabled = v
            if noclipEnabled then
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
    
    -- Infinite Jump toggle
    local infJumpEnabled = false
    
    Character:AddToggle("InfiniteJump", {
        Text = "Infinite Jump",
        Default = false,
        Callback = function(v)
            infJumpEnabled = v
            if infJumpEnabled then
                if not LocalPlayer.Character then return end
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then
                    hum:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
                end
                print("Infinite Jump enabled")
            else
                if LocalPlayer.Character then
                    local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                    if hum then
                        hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
                        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
                    end
                end
                print("Infinite Jump disabled")
            end
        end
    })
    
    -- Reset button
    Movement:AddButton("Reset Movement", function()
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = 16
                hum.JumpPower = 50
                hum.JumpHeight = 7.2
                hum.HipHeight = 2
            end
        end
        workspace.Gravity = 196.2
        print("Movement reset to default values")
    end)
    
    print("Player module loaded!")
    
    return {
        Cleanup = function()
            if flyConnection then
                flyConnection:Disconnect()
            end
            if noclipConnection then
                noclipConnection:Disconnect()
            end
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then
                    if flyEnabled then hum.PlatformStand = false end
                    if infJumpEnabled then
                        hum:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
                        hum:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
                    end
                end
                for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
            workspace.Gravity = 196.2
            print("Player cleanup!")
        end
    }
end

return Player
