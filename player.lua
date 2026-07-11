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
        LoopSpeed = false,
        LoopJump = false,
        InfJump = false,
        FlyEnabled = false,
        FlySpeed = 50,
        NoClip = false
    }
    
    self.Players = game:GetService("Players")
    self.LocalPlayer = self.Players.LocalPlayer
    self.RunService = game:GetService("RunService")
    self.UserInputService = game:GetService("UserInputService")
    
    self.FlyConnection = nil
    self.LoopConnection = nil
    self.InfJumpConnection = nil
    
    -- Создаем UI
    local Movement = Tab:AddLeftGroupbox("Movement")
    local Fly = Tab:AddRightGroupbox("Fly")
    local Other = Tab:AddLeftGroupbox("Other")
    
    -- Walk Speed
    Movement:AddToggle("CustomWalkSpeed", {
        Text = "Custom Walk Speed",
        Default = false,
        Callback = function(v) 
            self.PlayerEnv.Settings.CustomWalkSpeed = v
            if v then
                self:UpdateWalkSpeed()
            else
                self:ResetWalkSpeed()
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
            self:UpdateWalkSpeed()
        end
    })
    
    -- Loop Speed
    Movement:AddToggle("LoopSpeed", {
        Text = "Loop Speed",
        Default = false,
        Tooltip = "Forces walk speed every frame",
        Callback = function(v) 
            self.PlayerEnv.Settings.LoopSpeed = v
            if v then
                self:StartLoop()
            else
                self:StopLoop()
            end
        end
    })
    
    -- Jump Power
    Movement:AddToggle("CustomJumpPower", {
        Text = "Custom Jump Power",
        Default = false,
        Callback = function(v) 
            self.PlayerEnv.Settings.CustomJumpPower = v
            if v then
                self:UpdateJumpPower()
            else
                self:ResetJumpPower()
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
            self:UpdateJumpPower()
        end
    })
    
    -- Loop Jump
    Movement:AddToggle("LoopJump", {
        Text = "Loop Jump",
        Default = false,
        Tooltip = "Forces jump power every frame",
        Callback = function(v) 
            self.PlayerEnv.Settings.LoopJump = v
            if v then
                self:StartLoop()
            else
                self:StopLoop()
            end
        end
    })
    
    -- Infinite Jump
    Movement:AddToggle("InfJump", {
        Text = "Infinite Jump",
        Default = false,
        Callback = function(v) 
            self.PlayerEnv.Settings.InfJump = v
            if v then
                self:StartInfJump()
            else
                self:StopInfJump()
            end
        end
    })
    
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
    
    Fly:AddLabel("WASD - Move | Space - Up | Shift - Down")
    
    -- NoClip
    Other:AddToggle("NoClip", {
        Text = "No Clip",
        Default = false,
        Callback = function(v) 
            self.PlayerEnv.Settings.NoClip = v
            self:ApplyNoClip()
        end
    })
    
    print("Player module loaded!")
    return self
end

function Player:UpdateWalkSpeed()
    if self.LocalPlayer.Character then
        local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and self.PlayerEnv.Settings.CustomWalkSpeed then
            humanoid.WalkSpeed = self.PlayerEnv.Settings.WalkSpeed
        end
    end
end

function Player:ResetWalkSpeed()
    if self.LocalPlayer.Character then
        local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = 16
        end
    end
end

function Player:UpdateJumpPower()
    if self.LocalPlayer.Character then
        local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid and self.PlayerEnv.Settings.CustomJumpPower then
            humanoid.JumpPower = self.PlayerEnv.Settings.JumpPower
        end
    end
end

function Player:ResetJumpPower()
    if self.LocalPlayer.Character then
        local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = 50
        end
    end
end

function Player:StartLoop()
    if self.LoopConnection then return end
    
    self.LoopConnection = self.RunService.Heartbeat:Connect(function()
        if not self.LocalPlayer.Character then return end
        local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        if self.PlayerEnv.Settings.LoopSpeed then
            humanoid.WalkSpeed = self.PlayerEnv.Settings.WalkSpeed
        end
        
        if self.PlayerEnv.Settings.LoopJump then
            humanoid.JumpPower = self.PlayerEnv.Settings.JumpPower
        end
    end)
end

function Player:StopLoop()
    if self.LoopConnection and not self.PlayerEnv.Settings.LoopSpeed and not self.PlayerEnv.Settings.LoopJump then
        self.LoopConnection:Disconnect()
        self.LoopConnection = nil
    end
end

function Player:StartInfJump()
    if self.InfJumpConnection then return end
    
    self.InfJumpConnection = self.UserInputService.JumpRequest:Connect(function()
        if not self.PlayerEnv.Settings.InfJump then return end
        if not self.LocalPlayer.Character then return end
        
        local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

function Player:StopInfJump()
    if self.InfJumpConnection then
        self.InfJumpConnection:Disconnect()
        self.InfJumpConnection = nil
    end
end

function Player:ApplyNoClip()
    if not self.LocalPlayer.Character then return end
    
    for _, part in ipairs(self.LocalPlayer.Character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = not self.PlayerEnv.Settings.NoClip
        end
    end
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
    bodyGyro.MaxTorque = Vector3.new(400000, 400000, 400000)
    bodyGyro.P = 30000
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Name = "FlyVelocity"
    bodyVelocity.MaxForce = Vector3.new(400000, 400000, 400000)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart
    
    self.FlyConnection = self.RunService.Heartbeat:Connect(function()
        if not self.PlayerEnv.Settings.FlyEnabled then
            self:StopFly()
            return
        end
        
        if not rootPart or not rootPart.Parent then
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
            for _, child in ipairs(rootPart:GetChildren()) do
                if child.Name == "FlyGyro" or child.Name == "FlyVelocity" then
                    child:Destroy()
                end
            end
        end
    end
end

function Player:Cleanup()
    self:StopFly()
    self:StopLoop()
    self:StopInfJump()
    self:ResetWalkSpeed()
    self:ResetJumpPower()
    
    if self.LocalPlayer.Character then
        local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
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
