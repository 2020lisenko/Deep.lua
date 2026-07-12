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
    self.noclipEnabled = false
    self.InfiniteJumpEnabled = false
    
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
    
    -- Fly toggle с биндом
    local FlyToggle = Character:AddToggle("Fly", {
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
    
    FlyToggle:AddKeyPicker("FlyKeybind", {
        Text = "Fly Keybind",
        Default = "F",
        Mode = "Toggle",
        SyncToggleState = true,
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
    
    -- Noclip toggle с биндом
    local NoclipToggle = Character:AddToggle("Noclip", {
        Text = "Noclip",
        Default = false,
        Callback = function(v)
            self.noclipEnabled = v
            if v then
                self:StartNoclip()
            else
                self:StopNoclip()
            end
        end
    })
    
    NoclipToggle:AddKeyPicker("NoclipKeybind", {
        Text = "Noclip Keybind",
        Default = "G",
        Mode = "Toggle",
        SyncToggleState = true,
        Callback = function(v)
            self.noclipEnabled = v
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
            self.InfiniteJumpEnabled = v
        end
    })
    
    -- Initialize Infinite Jump connection
    self:SetupInfiniteJump()
    
    print("Player module loaded!")
    return self
end

function Player:SetupInfiniteJump()
    local conn = UserInputService.JumpRequest:Connect(function()
        if self.InfiniteJumpEnabled then
            local char = self.LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end
    end)
    table.insert(self.Connections, conn)
end

function Player:StartFly()
    self:StopFly()
    
    local char = self.LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    
    hum.PlatformStand = true
    
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.zero
    bv.Parent = root
    
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.D = 500
    bg.P = 3000
    bg.CFrame = workspace.CurrentCamera.CFrame
    bg.Parent = root
    
    self.flySpeed = self.flySpeed or 50
    
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not char or not char.Parent then
            self:StopFly()
            return
        end
        
        local currentRoot = char:FindFirstChild("HumanoidRootPart")
        local currentHum = char:FindFirstChild("Humanoid")
        if not currentRoot or not currentHum then
            self:StopFly()
            return
        end
        
        if not bv or not bv.Parent or not bg or not bg.Parent then
            self:StopFly()
            return
        end
        
        local cam = workspace.CurrentCamera
        if not cam then
            self:StopFly()
            return
        end
        
        bg.CFrame = cam.CFrame
        
        local flySpeed = self.flySpeed or 50
        local moveVel = Vector3.zero
        
        -- Движение вперед/назад (W/S)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVel = moveVel + cam.CFrame.LookVector * flySpeed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVel = moveVel - cam.CFrame.LookVector * flySpeed
        end
        
        -- Движение влево/вправо (A/D)
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVel = moveVel + cam.CFrame.RightVector * flySpeed
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVel = moveVel - cam.CFrame.RightVector * flySpeed
        end
        
        -- Вертикальное движение (Space/LeftControl)
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVel = moveVel + Vector3.new(0, flySpeed, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveVel = moveVel - Vector3.new(0, flySpeed, 0)
        end
        
        bv.Velocity = moveVel
    end)
    
    self.flyConnection = conn
    table.insert(self.Connections, conn)
    print("Fly enabled")
end

function Player:StopFly()
    if self.flyConnection then
        self.flyConnection:Disconnect()
        self.flyConnection = nil
    end
    
    local char = self.LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then 
            hum.PlatformStand = false 
        end
        
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
        if not self.noclipEnabled or not self.LocalPlayer.Character then
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

function Player:Cleanup()
    self:StopFly()
    self.noclipEnabled = false
    self.InfiniteJumpEnabled = false
    
    for _, conn in pairs(self.Connections) do
        if conn then pcall(function() conn:Disconnect() end) end
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
