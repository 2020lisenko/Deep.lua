-- Замените функции StartFly и StopFly:

function Player:StartFly()
    if self.FlyConnection then return end
    
    local character = self.LocalPlayer.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    
    -- Убираем анимации
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
    
    -- Создаем BodyPosition для удержания в воздухе
    local bodyPosition = Instance.new("BodyPosition")
    bodyPosition.Name = "FlyPosition"
    bodyPosition.Position = rootPart.Position
    bodyPosition.MaxForce = Vector3.new(100000, 100000, 100000)
    bodyPosition.P = 10000
    bodyPosition.D = 100
    bodyPosition.Parent = rootPart
    
    -- Создаем BodyGyro для стабилизации
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.Name = "FlyGyro"
    bodyGyro.MaxTorque = Vector3.new(100000, 100000, 100000)
    bodyGyro.P = 10000
    bodyGyro.CFrame = rootPart.CFrame
    bodyGyro.Parent = rootPart
    
    -- Сохраняем стартовую позицию
    local startPosition = rootPart.Position
    local flySpeed = self.PlayerEnv.Settings.FlySpeed
    
    self.FlyConnection = self.RunService.Heartbeat:Connect(function()
        if not self.PlayerEnv.Settings.FlyEnabled then
            self:StopFly()
            return
        end
        
        if not rootPart or not rootPart.Parent then
            self:StopFly()
            return
        end
        
        local camera = workspace.CurrentCamera
        local moveDirection = Vector3.new(0, 0, 0)
        
        -- Управление WASD
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
        
        -- Вверх/вниз
        if self.UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            moveDirection = moveDirection + Vector3.new(0, 1, 0)
        end
        if self.UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or self.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end
        
        -- Применяем движение
        if moveDirection.Magnitude > 0 then
            startPosition = startPosition + (moveDirection.Unit * flySpeed * 0.016)
        end
        
        -- Обновляем позицию
        bodyPosition.Position = startPosition
        bodyGyro.CFrame = CFrame.lookAt(rootPart.Position, rootPart.Position + camera.CFrame.LookVector)
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
            -- Возвращаем состояния
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            humanoid.PlatformStand = false
        end
        
        -- Удаляем все Fly объекты
        local rootPart = self.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            for _, child in ipairs(rootPart:GetChildren()) do
                if child.Name == "FlyPosition" or child.Name == "FlyGyro" then
                    child:Destroy()
                end
            end
        end
    end
end
