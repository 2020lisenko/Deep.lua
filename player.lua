local Player = {}
Player.__index = Player

function Player:Initialize(Tab)
    local self = setmetatable({}, Player)
    print("Player module loading...")
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    
    self.Connections = {}
    self.flyConnection = nil
    self.flyEnabled = false
    self.flySpeed = 50
    self.noclipConnection = nil
    self.noclipEnabled = false
    self.infJumpEnabled = false
    self.infJumpConnection = nil
    self.LocalPlayer = LocalPlayer
    
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
    
    -- Character features
    local Character = Tab:AddLeftGroupbox("Character")
    
    -- Fly toggle
    local FlyToggle = Character:AddToggle("Fly", {
        Text = "Fly",
        Default = false,
        Callback = function(v)
            self.flyEnabled = v
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChild("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if not hum or not root then return end
            
            if self.flyEnabled then
                -- Остановим предыдущее соединение если есть
                if self.flyConnection then
                    self.flyConnection:Disconnect()
                end
                
                -- Store references for closure
                local flyChar = char
                local flyRoot = root
                local flyHum = hum
                
                local bodyGyro = Instance.new("BodyGyro")
                bodyGyro.P = 10000
                bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bodyGyro.CFrame = flyRoot.CFrame
                bodyGyro.Parent = flyRoot
                
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bodyVelocity.Parent = flyRoot
                
                self.flyConnection = game:GetService("RunService").Heartbeat:Connect(function()
                    if self.flyEnabled and flyChar and flyRoot and flyHum and flyChar.Parent then
                        -- Align body to camera
                        bodyGyro.CFrame = workspace.CurrentCamera.CFrame
                        
                        -- Get movement input from humanoid
                        local moveDir = flyHum.MoveVector
                        local camDir = workspace.CurrentCamera.CFrame.LookVector
                        local camRight = workspace.CurrentCamera.CFrame.RightVector
                        local camUp = workspace.CurrentCamera.CFrame.UpVector
                        
                        -- Calculate movement relative to camera
                        local moveVector = (camDir * moveDir.Z + camRight * moveDir.X) * self.flySpeed
                        
                        -- Handle vertical movement (Space to go up, Ctrl to go down)
                        local verticalMove = Vector3.new(0, 0, 0)
                        if flyHum.Jump then
                            verticalMove = camUp * self.flySpeed
                            flyHum.Jump = false
                        end
                        
                        -- Apply velocity
                        bodyVelocity.Velocity = moveVector + verticalMove
                    end
                end)
                print("Fly enabled")
            else
                if self.flyConnection then
                    self.flyConnection:Disconnect()
                    self.flyConnection = nil
                end
                if root then
                    local bg = root:FindFirstChild("BodyGyro")
                    local bv = root:FindFirstChild("BodyVelocity")
                    if bg then bg:Destroy() end
                    if bv then bv:Destroy() end
                end
                print("Fly disabled")
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
    local NoclipToggle = Character:AddToggle("Noclip", {
        Text = "Noclip",
        Default = false,
        Callback = function(v)
            self.noclipEnabled = v
            if self.noclipEnabled then
                self.noclipConnection = game:GetService("RunService").Stepped:Connect(function()
                    if self.noclipEnabled and LocalPlayer.Character then
                        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end)
                print("Noclip enabled")
            else
                if self.noclipConnection then
                    self.noclipConnection:Disconnect()
                    self.noclipConnection = nil
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
    local InfJumpToggle = Character:AddToggle("InfiniteJump", {
        Text = "Infinite Jump",
        Default = false,
        Callback = function(v)
            self.infJumpEnabled = v
            if self.infJumpEnabled then
                if self.infJumpConnection then
                    self.infJumpConnection:Disconnect()
                end
                self.infJumpConnection = game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if self.infJumpEnabled and input.KeyCode == Enum.KeyCode.Space then
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
                if self.infJumpConnection then
                    self.infJumpConnection:Disconnect()
                    self.infJumpConnection = nil
                end
                print("Infinite Jump disabled")
            end
        end
    })
    
    -- Reset button
    Movement:AddButton("Reset Movement", function()
        local defaultWalkSpeed = 16
        local defaultJumpHeight = 7.2
        
        -- Устанавливаем значения слайдеров
        WalkSpeedSlider:SetValue(defaultWalkSpeed)
        JumpHeightSlider:SetValue(defaultJumpHeight)
        
        -- Применяем значения к персонажу
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum then
                hum.WalkSpeed = defaultWalkSpeed
                hum.JumpHeight = defaultJumpHeight
            end
        end
        print("Movement reset to default values")
    end)
    
    print("Player module loaded!")
    
    self.WalkSpeedSlider = WalkSpeedSlider
    self.JumpHeightSlider = JumpHeightSlider
    
    return self
end

function Player:Cleanup()
    if self.flyConnection then
        self.flyConnection:Disconnect()
    end
    if self.noclipConnection then
        self.noclipConnection:Disconnect()
    end
    if self.infJumpConnection then
        self.infJumpConnection:Disconnect()
    end
    if self.LocalPlayer.Character then
        local root = self.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            local bg = root:FindFirstChild("BodyGyro")
            local bv = root:FindFirstChild("BodyVelocity")
            if bg then bg:Destroy() end
            if bv then bv:Destroy() end
        end
        for _, part in pairs(self.LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    print("Player cleanup!")
end

return Player
