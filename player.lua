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
    self.flySpeed = 50
    
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
    
    -- Обработка респавна (чтобы скрипт не ломался при смерти)
    local respawnConn = self.LocalPlayer.CharacterAdded:Connect(function(newChar)
        -- Отключаем эффекты при смерти, чтобы не было багов с новым персонажем
        if self.flyConnection then self:StopFly() end
    end)
    table.insert(self.Connections, respawnConn)
    
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
    self:StopFly() -- Убеждаемся, что старый полет выключен
    
    local char = self.LocalPlayer.Character
    if not char then return end
    
    local hum = char:FindFirstChild("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    
    hum.PlatformStand = true
    
    -- Создаем и сохраняем ссылки только на НАШИ BodyMovers
    self.flyBV = Instance.new("BodyVelocity")
    self.flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    self.flyBV.Velocity = Vector3.zero
    self.flyBV.Parent = root
    
    self.flyBG = Instance.new("BodyGyro")
    self.flyBG.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    self.flyBG.D = 500
    self.flyBG.P = 3000
    self.flyBG.CFrame = workspace.CurrentCamera.CFrame
    self.flyBG.Parent = root
    
    self.flyConnection = RunService.RenderStepped:Connect(function()
        if not char or not char.Parent or hum.Health <= 0 then
            self:StopFly()
            return
        end
        
        local cam = workspace.CurrentCamera
        if not cam or not self.flyBV or not self.flyBG then return end
        
        self.flyBG.CFrame = cam.CFrame
        
        local currentFlySpeed = self.flySpeed or 50
        local moveVel = Vector3.zero
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then
            moveVel = moveVel + cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then
            moveVel = moveVel - cam.CFrame.LookVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then
            moveVel = moveVel + cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then
            moveVel = moveVel - cam.CFrame.RightVector
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveVel = moveVel + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveVel = moveVel - Vector3.new(0, 1, 0)
        end
        
        -- Нормализуем вектор, чтобы при диагональном полете скорость не увеличивалась
        if moveVel.Magnitude > 0 then
            moveVel = moveVel.Unit * currentFlySpeed
        end
        
        self.flyBV.Velocity = moveVel
    end)
    
    print("Fly enabled")
end

function Player:StopFly()
    if self.flyConnection then
        self.flyConnection:Disconnect()
        self.flyConnection = nil
    end
    
    if self.flyBV then
        self.flyBV:Destroy()
        self.flyBV = nil
    end
    
    if self.flyBG then
        self.flyBG:Destroy()
        self.flyBG = nil
    end
    
    local char = self.LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then 
            hum.PlatformStand = false 
        end
    end
    
    print("Fly disabled")
end

function Player:StartNoclip()
    self:StopNoclip() -- Очищаем старый коннект, если он был
    
    self.noclipConnection = RunService.Stepped:Connect(function()
        if not self.noclipEnabled then return end
        
        local char = self.LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end)
    print("Noclip enabled")
end

function Player:StopNoclip()
    if self.noclipConnection then
        self.noclipConnection:Disconnect()
        self.noclipConnection = nil
    end
    
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
    self:StopNoclip()
    self.noclipEnabled = false
    self.InfiniteJumpEnabled = false
    
    for _, conn in pairs(self.Connections) do
        if conn then pcall(function() conn:Disconnect() end) end
    end
    self.Connections = {}
    
    print("Player cleanup complete!")
end

return Player
