local Player = {}

function Player:Initialize(Tab)
    print("Player module loading...")
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    
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
        Max = 200,
        Rounding = 1,
        Callback = function(v)
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChild("Humanoid")
                if hum then
                    hum.JumpHeight = v
                    hum.JumpPower = math.sqrt(2 * workspace.Gravity * v)
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
            if not char then 
                if v then
                    warn("Character not found for fly")
                end
                return 
            end
            local hum = char:FindFirstChild("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            if not hum or not root then 
                if v then
                    warn("Humanoid or RootPart not found for fly")
                end
                return 
            end
            
            if flyEnabled then
                if flyConnection then flyConnection:Disconnect() end
                
                -- Удаляем старые объекты если есть
                if bodyGyro then bodyGyro:Destroy() end
                if bodyVelocity then bodyVelocity:Destroy() end
                
                -- Создаем новые объекты
                bodyGyro = Instance.new("BodyGyro")
                bodyGyro.P = 9e4
                bodyGyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
                bodyGyro.CFrame = root.CFrame
                bodyGyro.Parent = root
                
                bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
                bodyVelocity.Velocity = Vector3.zero
                bodyVelocity.Parent = root
                
                -- Отключаем гравитацию для персонажа
                hum.PlatformStand = true
                
                local speed = 50 -- Базовая скорость полета
                
                flyConnection = RunService.Heartbeat:Connect(function()
                    if not flyEnabled or not char or not char.Parent or not root or not root.Parent then 
                        -- Автоматически выключаем полет если персонаж исчез
                        flyEnabled = false
                        if hum and hum.Parent then
                            hum.PlatformStand = false
                        end
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
                    
                    -- Получаем направление камеры
                    local camera = workspace.CurrentCamera
                    local cameraCFrame = camera.CFrame
                    
                    -- Поворачиваем персонажа в направлении камеры
                    if bodyGyro and bodyGyro.Parent then
                        bodyGyro.CFrame = cameraCFrame
                    end
                    
                    -- Рассчитываем скорость на основе направления камеры
                    local velocity = Vector3.zero
                    local moving = false
                    
                    -- Вперед/назад (W/S) - летит туда куда смотрит камера
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                        velocity = velocity + cameraCFrame.LookVector * speed
                        moving = true
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                        velocity = velocity - cameraCFrame.LookVector * speed
                        moving = true
                    end
                    
                    -- Влево/вправо (A/D)
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                        velocity = velocity - cameraCFrame.RightVector * speed
                        moving = true
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                        velocity = velocity + cameraCFrame.RightVector * speed
                        moving = true
                    end
                    
                    -- Дополнительное управление высотой
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        velocity = velocity + Vector3.new(0, speed, 0)
                        moving = true
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                        velocity = velocity - Vector3.new(0, speed, 0)
                        moving = true
                    end
                    
                    -- Если ни одна клавиша не нажата - останавливаемся
                    if not moving then
                        velocity = Vector3.zero
                    end
                    
                    -- Применяем скорость
                    if bodyVelocity and bodyVelocity.Parent then
                        bodyVelocity.Velocity = velocity
                    end
                end)
                print("Fly enabled - W: Forward (camera direction), S: Backward, Space: Up, Shift/Ctrl: Down")
            else
                -- Выключаем полет
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
                if hum and hum.Parent then
                    hum.PlatformStand = false
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
                noclipConnection = RunService.Stepped:Connect(function()
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
                infJumpConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
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
                hum.JumpPower = 50
            end
        end
        print("Movement reset")
    end)
    
    -- Добавляем обработчик для автоматического обновления при спавне
    local function onCharacterAdded(char)
        local hum = char:WaitForChild("Humanoid")
        if hum then
            hum.WalkSpeed = WalkSpeedSlider:GetValue() or 16
            local jumpHeight = JumpHeightSlider:GetValue() or 7.2
            hum.JumpHeight = jumpHeight
            hum.JumpPower = math.sqrt(2 * workspace.Gravity * jumpHeight)
        end
    end
    
    LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
    
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
                local hum = LocalPlayer.Character:FindFirstChild("Humanoid")
                if hum then
                    hum.PlatformStand = false
                    hum.WalkSpeed = 16
                    hum.JumpHeight = 7.2
                    hum.JumpPower = 50
                end
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
