local Player = {}
Player.__index = Player

function Player:Initialize(Tab)
    local self = setmetatable({}, Player)
    
    if not getgenv().DeepPlayer then
        getgenv().DeepPlayer = {}
    end
    
    self.PlayerEnv = getgenv().DeepPlayer
    
    self.Players = game:GetService("Players")
    self.LocalPlayer = self.Players.LocalPlayer
    self.RunService = game:GetService("RunService")
    self.UserInputService = game:GetService("UserInputService")
    
    self.FlyConnection = nil
    self.SpeedConnection = nil
    self.JumpConnection = nil
    
    self.OriginalValues = {
        WalkSpeed = 16,
        JumpPower = 50
    }
    
    self:LoadDefaultSettings()
    self:CreateUI(Tab)
    
    return self
end

function Player:LoadDefaultSettings()
    self.PlayerEnv.Settings = {
        CustomWalkSpeed = false,
        WalkSpeed = 16,
        CustomJumpPower = false,
        JumpPower = 50,
        FlyEnabled = false,
        FlySpeed = 50,
        NoClip = false,
        AntiAFK = false
    }
end

function Player:ApplyWalkSpeed()
    if self.PlayerEnv.Settings.CustomWalkSpeed then
        self:StartSpeedLoop()
    else
        self:StopSpeedLoop()
        if self.LocalPlayer.Character then
            local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = self.OriginalValues.WalkSpeed
            end
        end
    end
end

function Player:StartSpeedLoop()
    if self.SpeedConnection then return end
    
    self.SpeedConnection = self.RunService.Heartbeat:Connect(function()
        if self.LocalPlayer.Character then
            local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and self.PlayerEnv.Settings.CustomWalkSpeed then
                humanoid.WalkSpeed = self.PlayerEnv.Settings.WalkSpeed
            end
        end
    end)
end

function Player:StopSpeedLoop()
    if self.SpeedConnection then
        self.SpeedConnection:Disconnect()
        self.SpeedConnection = nil
    end
end

function Player:ApplyJumpPower()
    if self.PlayerEnv.Settings.CustomJumpPower then
        self:StartJumpLoop()
    else
        self:StopJumpLoop()
        if self.LocalPlayer.Character then
            local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = self.OriginalValues.JumpPower
            end
        end
    end
end

function Player:StartJumpLoop()
    if self.JumpConnection then return end
    
    self.JumpConnection = self.RunService.Heartbeat:Connect(function()
        if self.LocalPlayer.Character then
            local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and self.PlayerEnv.Settings.CustomJumpPower then
                humanoid.JumpPower = self.PlayerEnv.Settings.JumpPower
            end
        end
    end)
end

function Player:StopJumpLoop()
    if self.JumpConnection then
        self.JumpConnection:Disconnect()
        self.JumpConnection = nil
    end
end

function Player:ApplyFly()
    if self.PlayerEnv.Settings.FlyEnabled then
        self:StartFly()
    else
        self:StopFly()
    end
end

function Player:StartFly()
    if self.FlyConnection then return end
    
    local character = self.LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:WaitForChild("Humanoid")
    local rootPart = character:WaitForChild("HumanoidRootPart")
    
    humanoid.PlatformStand = true
    
    self.FlyConnection = self.RunService.Heartbeat:Connect(function()
        if not self.PlayerEnv.Settings.FlyEnabled then
            self:StopFly()
            return
        end
        
        local speed = self.PlayerEnv.Settings.FlySpeed
        local camera = workspace.CurrentCamera
        
        if self.UserInputService:IsKeyDown(Enum.KeyCode.W) then
            rootPart.CFrame = rootPart.CFrame + (camera.CFrame.LookVector * speed * 0.1)
        end
        if self.UserInputService:IsKeyDown(Enum.KeyCode.S) then
            rootPart.CFrame = rootPart.CFrame - (camera.CFrame.LookVector * speed * 0.1)
        end
        if self.UserInputService:IsKeyDown(Enum.KeyCode.A) then
            rootPart.CFrame = rootPart.CFrame - (camera.CFrame.RightVector * speed * 0.1)
        end
        if self.UserInputService:IsKeyDown(Enum.KeyCode.D) then
            rootPart.CFrame = rootPart.CFrame + (camera.CFrame.RightVector * speed * 0.1)
        end
        if self.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            rootPart.CFrame = rootPart.CFrame + (Vector3.new(0, 1, 0) * speed * 0.1)
        end
        if self.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            rootPart.CFrame = rootPart.CFrame - (Vector3.new(0, 1, 0) * speed * 0.1)
        end
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
    end
end

function Player:ApplyNoClip()
    if self.PlayerEnv.Settings.NoClip then
        self:StartNoClip()
    else
        self:StopNoClip()
    end
end

function Player:StartNoClip()
    local character = self.LocalPlayer.Character
    if not character then return end
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
    
    character.DescendantAdded:Connect(function(child)
        if child:IsA("BasePart") then
            child.CanCollide = false
        end
    end)
end

function Player:StopNoClip()
    local character = self.LocalPlayer.Character
    if not character then return end
    
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = true
        end
    end
end

function Player:RestoreAll()
    self:StopFly()
    self:StopSpeedLoop()
    self:StopJumpLoop()
    
    if self.LocalPlayer.Character then
        local humanoid = self.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.WalkSpeed = self.OriginalValues.WalkSpeed
            humanoid.JumpPower = self.OriginalValues.JumpPower
            humanoid.PlatformStand = false
        end
        
        for _, part in ipairs(self.LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    
    self:LoadDefaultSettings()
    print("Player settings restored to defaults!")
end

function Player:CreateUI(Tab)
    local Movement = Tab:AddLeftGroupbox("Movement")
    local Fly = Tab:AddRightGroupbox("Fly")
    local Other = Tab:AddLeftGroupbox("Other")
    
    -- Movement Group
    Movement:AddToggle("CustomWalkSpeed", {
        Text = "Custom Walk Speed",
        Default = false,
        Callback = function(v) 
            self.PlayerEnv.Settings.CustomWalkSpeed = v
            self:ApplyWalkSpeed()
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
            self:ApplyJumpPower()
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
    
    -- Fly Group
    Fly:AddToggle("FlyEnabled", {
        Text = "Fly",
        Default = false,
        Callback = function(v) 
            self.PlayerEnv.Settings.FlyEnabled = v
            self:ApplyFly()
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
    
    Fly:AddLabel("Fly Controls:")
    Fly:AddLabel("W/A/S/D - Move")
    Fly:AddLabel("Space - Up")
    Fly:AddLabel("Shift - Down")
    
    -- Other Group
    Other:AddToggle("NoClip", {
        Text = "No Clip",
        Default = false,
        Callback = function(v) 
            self.PlayerEnv.Settings.NoClip = v
            self:ApplyNoClip()
        end
    })
    
    Other:AddDivider()
    Other:AddButton("Restore Defaults", function()
        self:RestoreAll()
    end)
end

function Player:Cleanup()
    self:RestoreAll()
end

return Player
