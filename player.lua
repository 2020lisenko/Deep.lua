local Player = {}
Player.__index = Player

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

function Player:Initialize(Tab)
    local self = setmetatable({}, Player)
    print("Player module loading...")
    
    self.LocalPlayer = Players.LocalPlayer
    self.Connections = {}
    
    -- Fly system
    self.flyActive = false
    self.flySpeed = 50
    self.flyConnection = nil
    
    local Movement = Tab:AddLeftGroupbox("Movement")
    
    -- WalkSpeed
    Movement:AddSlider("WalkSpeed", {
        Text = "Walk Speed",
        Default = 16,
        Min = 1,
        Max = 200,
        Rounding = 0,
        Callback = function(v)
            local char = self.LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = v
            end
        end
    })
    
    -- JumpHeight
    Movement:AddSlider("JumpHeight", {
        Text = "Jump Height",
        Default = 7.2,
        Min = 1,
        Max = 50,
        Rounding = 1,
        Callback = function(v)
            local char = self.LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.JumpHeight = v
            end
        end
    })
    
    -- Character features
    local Character = Tab:AddLeftGroupbox("Character")
    
    -- Fly toggle
    Character:AddToggle("Fly", {
        Text = "Fly",
        Default = false,
        Callback = function(v)
            if v then
                self:StartFly()
            else
                self:StopFly()
            end
        end
    })
    
    -- Fly Speed slider
    Character:AddSlider("FlySpeed", {
        Text = "Fly Speed",
        Default = 50,
        Min = 10,
        Max = 200,
        Rounding = 0,
        Callback = function(v)
            self.flySpeed = v
        end
    })
    
    -- Noclip toggle
    Character:AddToggle("Noclip", {
        Text = "Noclip",
        Default = false,
        Callback = function(v)
            if v then
                self:StartNoclip()
            else
                self:StopNoclip()
            end
        end
    })
    
    -- Infinite Jump toggle
    Character:AddToggle("InfiniteJump", {
        Text = "Infinite Jump",
        Default = false,
        Callback = function(v)
            if v then
                self:StartInfJump()
            else
                self:StopInfJump()
            end
        end
    })
    
    print("Player module loaded!")
    return self
end

function Player:StartFly()
    self:StopFly()
    
    local char = self.LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    
    -- Disable gravity
    hum.PlatformStand = true
    
    -- Create physics objects
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Parent = root
    
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.D = 500
    bg.Parent = root
    
    self.flyActive = true
    
    self.flyConnection = RunService.RenderStepped:Connect(function()
        if not self.flyActive or not char or not char.Parent then
            self:StopFly()
            return
        end
        
        local currentRoot = char:FindFirstChild("HumanoidRootPart")
        local currentHum = char:FindFirstChild("Humanoid")
        
        if not currentRoot or not currentHum then
            self:StopFly()
            return
        end
        
        local cam = workspace.CurrentCamera
        bg.CFrame = cam.CFrame
        
        -- Get movement
        local moveDir = currentHum.MoveVector
        local moveVel = (cam.CFrame.LookVector * moveDir.Z + cam.CFrame.RightVector * moveDir.X) * self.flySpeed
        
        -- Vertical movement
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVel = moveVel + cam.CFrame.UpVector * self.flySpeed
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveVel = moveVel - cam.CFrame.UpVector * self.flySpeed
        end
        
        bv.Velocity = moveVel
    end)
    
    print("Fly enabled")
end

function Player:StopFly()
    self.flyActive = false
    
    if self.flyConnection then
        self.flyConnection:Disconnect()
        self.flyConnection = nil
    end
    
    local char = self.LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end
        
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            for _, obj in pairs(root:GetChildren()) do
                if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then
                    obj:Destroy()
                end
            end
        end
    end
    
    print("Fly disabled")
end

function Player:StartNoclip()
    local conn
    conn = RunService.Stepped:Connect(function()
        if not self.LocalPlayer.Character then
            conn:Disconnect()
            return
        end
        for _, part in pairs(self.LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
    table.insert(self.Connections, conn)
    print("Noclip enabled")
end

function Player:StopNoclip()
    local char = self.LocalPlayer.Character
    if char then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    print("Noclip disabled")
end

function Player:StartInfJump()
    local conn
    conn = UserInputService.InputBegan:Connect(function(input, gp)
        if gp or input.KeyCode ~= Enum.KeyCode.Space then return end
        local char = self.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
    table.insert(self.Connections, conn)
    print("Infinite Jump enabled")
end

function Player:StopInfJump()
    print("Infinite Jump disabled")
end

function Player:Cleanup()
    self:StopFly()
    self:StopNoclip()
    
    for _, conn in pairs(self.Connections) do
        if conn then conn:Disconnect() end
    end
    self.Connections = {}
    
    local char = self.LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then hum.PlatformStand = false end
        
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
    
    print("Player cleanup!")
end

return Player
