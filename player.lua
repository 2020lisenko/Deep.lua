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
