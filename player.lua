local Player = {}

function Player:Initialize(Tab)
    print("Player module loading...")
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    
    local flyConnection = nil
    local flyBodyGyro = nil
    local flyBodyVelocity = nil
    local walkSpeedEnabled = false
    local walkSpeedValue = 16
    local flySpeed = 50
    
    local Movement = Tab:AddLeftGroupbox("Movement")
    local FlyGroup = Tab:AddRightGroupbox("Fly")
    
    -- Walk Speed Toggle
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
    
    -- Walk Speed Slider
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
    
    -- Fly Start
    local function startFly()
        local char = LocalPlayer.Character
        if not char then return end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        flyBodyGyro = Instance.new("BodyGyro")
        flyBodyGyro.P = 9e4
        flyBodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBodyGyro.CFrame = hrp.CFrame
        flyBodyGyro.Parent = hrp
        
        flyBodyVelocity = Instance.new("BodyVelocity")
        flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
        flyBodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBodyVelocity.Parent = hrp
        
        flyConnection = RunService.RenderStepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChild("Humanoid")
            if not hrp or not hum then return end
            
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
    
    -- Fly Stop
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
    
    -- Fly Toggle
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
    
    -- Fly Speed Slider
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
    
    print("Player module loaded!")
    
    return {
        Cleanup = function()
            print("Player cleanup!")
            stopFly()
        end
    }
end

return Player
