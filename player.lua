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
    
    local flyToggle = Character:AddToggle("Fly", {
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
                if flyConnection then 
                    flyConnection:Disconnect()
                    flyConnection = nil
                end
                
                -- Удаляем старые объекты если есть
                if bodyGyro then 
                    bodyGyro:Destroy()
                    bodyGyro = nil
                end
                if bodyVelocity then 
                    bodyVelocity:Destroy()
                    bodyVelocity = nil
                end
                
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
                        if flyToggle then
                            flyToggle:SetValue(false)
                        end
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
                    
                    -- Обновляем поворот
                    if bodyGyro and bodyGyro.Parent then
                        bodyGyro.CFrame = workspace.CurrentCamera.CFrame
                    end
                    
                    -- Рассчитываем скорость
                    local velocity = Vector3.zero
                    
                    -- Горизонтальное движение
                    local moveDirection = hum.MoveDirection
                    if moveDirection.Magnitude > 0 then
                        velocity = moveDirection * speed
                    end
                    
                    -- Вертикальное движение
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                        velocity = velocity + Vector3.new(0, speed, 0) -- Вверх
                    end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                        velocity = velocity + Vector3.new(0, -speed, 0) -- Вниз
                    end
                    
                    -- Применяем скорость
                    if bodyVelocity and bodyVelocity.Parent then
                        bodyVelocity.Velocity = velocity
                    end
                end)
                print("Fly enabled - Space: Up, Shift/Ctrl: Down")
            else
                -- Выключаем полет
                cleanupFly()
            end
        end
    })
    
    -- Функция очистки полета
    function cleanupFly()
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
        local char = LocalPlayer.Character
        if char then
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum.Parent then
                hum.PlatformStand = false
            end
        end
        print("Fly disabled")
    end
    
    -- Noclip
    local noclipConnection
    local noclipEnabled = false
    
    Character:AddToggle("Noclip", {
        Text = "Noclip",
        Default = false,
        Callback = function(v)
            noclipEnabled = v
            if noclipEnabled then
                if noclipConnection then 
                    noclipConnection:Disconnect()
                    noclipConnection = nil
                end
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
                if infJumpConnection then 
                    infJumpConnection:Disconnect()
                    infJumpConnection = nil
                end
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
                hum.JumpPower = 50 -- Стандартное значение JumpPower
            end
        end
        print("Movement reset")
    end)
    
    -- Обработчик для автоматического обновления при спавне
    local function onCharacterAdded(char)
        local hum = char:WaitForChild("Humanoid")
        if hum then
            -- Применяем текущие настройки из слайдеров
            hum.WalkSpeed = WalkSpeedSlider:GetValue() or 16
            local jumpHeight = JumpHeightSlider:GetValue() or 7.2
            hum.JumpHeight = jumpHeight
            hum.JumpPower = math.sqrt(2 * workspace.Gravity * jumpHeight)
        end
        
        -- Если полет был включен, перезапускаем его
        if flyEnabled and flyToggle then
            flyToggle:SetValue(false)
            wait()
            flyToggle:SetValue(true)
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
            flyEnabled = false
            noclipEnabled = false
            infJumpEnabled = false
            print("Player cleanup!")
        end
    }
end

return Player
