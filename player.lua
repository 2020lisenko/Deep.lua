local Player = {}
Player.__index = Player

function Player:Initialize(Tab)
    print("Player module initializing...")
    local self = setmetatable({}, Player)
    
    if not getgenv().DeepPlayer then
        getgenv().DeepPlayer = {}
    end
    
    self.PlayerEnv = getgenv().DeepPlayer
    self.PlayerEnv.Settings = {
        CustomWalkSpeed = false,
        WalkSpeed = 16,
        CustomJumpPower = false,
        JumpPower = 50,
        FlyEnabled = false,
        FlySpeed = 50,
        NoClip = false,
        AntiSpeedReset = false,
        AntiJumpReset = false
    }
    
    self.Players = game:GetService("Players")
    self.LocalPlayer = self.Players.LocalPlayer
    self.RunService = game:GetService("RunService")
    self.UserInputService = game:GetService("UserInputService")
    
    self.FlyConnection = nil
    self.SpeedConnection = nil
    self.JumpConnection = nil
    self.AntiResetConnection = nil
    
    local Movement = Tab:AddLeftGroupbox("Movement")
    local Fly = Tab:AddRightGroupbox("Fly")
    local AntiCheat = Tab:AddLeftGroupbox("Anti-Cheat Bypass")
    
    -- Movement
    Movement:AddToggle("CustomWalkSpeed", {
        Text = "Custom Walk Speed",
        Default = false,
        Callback = function(v) 
            self.PlayerEnv.Settings.CustomWalkSpeed = v
            if v then
                self:StartSpeedLoop()
            else
                self:StopSpeedLoop()
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
            self.PlayerEnv.Settings.WalkSpeed = v
        end
    })
    
    Movement:AddToggle("CustomJumpPower", {
        Text = "Custom Jump Power",
        Default = false,
        Callback = function(v) 
            self.PlayerEnv.Settings.CustomJumpPower = v
            if v then
                self:StartJumpLoop()
            else
                self:StopJumpLoop()
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
            self.PlayerEnv.Settings.JumpPower = v
        end
    })
    
    -- Anti-Cheat Bypass
    AntiCheat:AddToggle("AntiSpeedReset", {
        Text = "Anti Speed Reset",
        Default = false,
        Tooltip = "Prevents anti-cheat from resetting walk speed",
        Callback = function(v) 
            self.PlayerEnv.Settings.AntiSpeedReset = v
            if v then
                self:StartAntiReset()
            else
                self:StopAntiReset()
            end
        end
    })
    
    AntiCheat:AddToggle("AntiJumpReset", {
        Text = "Anti Jump Reset",
        Default = false,
        Tooltip = "Prevents anti-cheat from resetting jump power",
        Callback = function(v) 
            self.PlayerEnv.Settings.AntiJumpReset = v
            if v then
                self:StartAntiReset()
            else
                self:StopAntiReset()
            end
        end
    })
    
    AntiCheat:AddLabel("Works with Custom Speed/Jump")
    AntiCheat:AddLabel("Forces values every frame")
    
    -- Fly
    Fly:AddToggle("FlyEnabled", {
        Text = "Fly",
        Default = false,
        Callback = function(v) 
            self.PlayerEnv.Settings.FlyEnabled = v
            if v then
                self:StartFly()
            else
                self:StopFly()
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
            self.PlayerEnv.Settings.FlySpeed = v
        end
    })
    
    Fly:AddLabel("Controls: WASD/Space/Shift")
    
    -- NoClip отдельно
    local Other = Tab:AddRightGroupbox("Other")
    Other:AddToggle("NoClip", {
        Text = "No Clip",
        Default = false,
        Callback = function(v) 
            self.PlayerEnv.Settings.NoClip = v
            if self.LocalPlayer.Character then
                for _, part in ipairs(self.LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = not v
                    end
                end
            end
        end
    })
    
    print("Player module loaded!")
    return self
end

-- Anti-Reset система
function Player:StartAntiReset()
    if self.AntiResetConnection then return end
    
    self.AntiResetConnection = self.RunService.Heartbeat:Connect(function()
        if not self.LocalPlayer.Character then return end
        local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        -- Принудительно устанавливаем скорость каждый кадр
        if self.PlayerEnv.Settings.AntiSpeedReset and self.PlayerEnv.Settings.CustomWalkSpeed then
            humanoid.WalkSpeed = self.PlayerEnv.Settings.WalkSpeed
        end
        
        -- Принудительно устанавливаем прыжок каждый кадр
        if self.PlayerEnv.Settings.AntiJumpReset and self.PlayerEnv.Settings.CustomJumpPower then
            humanoid.JumpPower = self.PlayerEnv.Settings.JumpPower
        end
    end)
end

function Player:StopAntiReset()
    if self.AntiResetConnection and not self.PlayerEnv.Settings.AntiSpeedReset and not self.PlayerEnv.Settings.AntiJumpReset then
        self.AntiResetConnection:Disconnect()
        self.AntiResetConnection = nil
    end
end

function Player:StartSpeedLoop()
    if self.SpeedConnection then return end
    self.SpeedConnection = self.RunService.Heartbeat:Connect(function()
        if self.LocalPlayer.Character and self.PlayerEnv.Settings.CustomWalkSpeed then
            local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = self.PlayerEnv.Settings.WalkSpeed
            end
        end
    end)
    
    -- Запускаем анти-ресет если нужно
    if self.PlayerEnv.Settings.AntiSpeedReset and not self.AntiResetConnection then
        self:StartAntiReset()
    end
end

function Player:StopSpeedLoop()
    if self.SpeedConnection then
        self.SpeedConnection:Disconnect()
        self.SpeedConnection = nil
    end
    if self.LocalPlayer.Character then
        local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
        end
    end
    
    self:StopAntiReset()
end

function Player:StartJumpLoop()
    if self.JumpConnection then return end
    self.JumpConnection = self.RunService.Heartbeat:Connect(function()
        if self.LocalPlayer.Character and self.PlayerEnv.Settings.CustomJumpPower then
            local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = self.PlayerEnv.Settings.JumpPower
            end
        end
    end)
    
    -- Запускаем анти-ресет если нужно
    if self.PlayerEnv.Settings.AntiJumpReset and not self.AntiResetConnection then
        self:StartAntiReset()
    end
end

function Player:StopJumpLoop()
    if self.JumpConnection then
        self.JumpConnection:Disconnect()
        self.JumpConnection = nil
    end
    if self.LocalPlayer.Character then
        local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = 50
        end
    end
    
    self:StopAntiReset()
end

function Player:StartFly()
    if self.FlyConnection then return end
    
    local character = self.LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    
    humanoid.PlatformStand = true
    
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "FlyGyro"
    bodyGyro.P = 0
    bodyGyro.MaxTorque = Vector3.new(0, 0, 0)
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "FlyVelocity"
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
    bodyVelocity.Parent = rootPart
    
    self.FlyConnection = self.RunService.Heartbeat:Connect(function()
        if not self.PlayerEnv.Settings.FlyEnabled then
            self:StopFly()
            return
        end
        
        local speed = self.PlayerEnv.Settings.FlySpeed
        local camera = workspace.CurrentCamera
        local moveDirection = Vector3.new(0, 0, 0)
        
        if self.UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveDirection = moveDirection + camera.CFrame.LookVector
        end
        if self.UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveDirection = moveDirection - camera.CFrame.LookVector
        end
        if self.UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveDirection = moveDirection - camera.CFrame.RightVector
        end
        if self.UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveDirection = moveDirection + camera.CFrame.RightVector
        end
        if self.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if self.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end
        
        if moveDirection.Magnitude > 0 then
            bodyVelocity.Velocity = moveDirection.Unit * speed
        else
            bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        end
        
        bodyGyro.CFrame = camera.CFrame
    end)
end

function Player:StopFly()
    if self.FlyConnection then
        self.FlyConnection:Disconnect()
        self.FlyConnection = nil
    end
    
    if self.LocalPlayer.Character then
        local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
        end
        
        local rootPart = self.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local gyro = rootPart:FindFirstChild("FlyGyro")
            if gyro then gyro:Destroy() end
            
            local velocity = rootPart:FindFirstChild("FlyVelocity")
            if velocity then velocity:Destroy() end
        end
    end
end

function Player:Cleanup()
    self:StopFly()
    self:StopSpeedLoop()
    self:StopJumpLoop()
    
    if self.AntiResetConnection then
        self.AntiResetConnection:Disconnect()
        self.AntiResetConnection = nil
    end
    
    if self.LocalPlayer.Character then
        local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
            humanoid.JumpPower = 50
            humanoid.PlatformStand = false
        end
        
        for _, part in ipairs(self.LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

return Player
