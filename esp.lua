local ESP = {}
ESP.__index = ESP

function ESP:Initialize(Tab)
    local self = setmetatable({}, ESP)
    
    if not getgenv().DeepESP then
        getgenv().DeepESP = {}
    end
    
    self.ESPEnv = getgenv().DeepESP
    self.Players = game:GetService("Players")
    self.RunService = game:GetService("RunService")
    self.Camera = workspace.CurrentCamera
    self.LocalPlayer = self.Players.LocalPlayer
    self.ESP_DB = false
    self.Active = false
    
    self.playerESP = {}
    self.globalTime = 0
    
    self:LoadDefaultSettings()
    self:CreateUI(Tab)
    
    return self
end

function ESP:LoadDefaultSettings()
    self.ESPEnv.Settings = {
        Enabled = false,
        TeamCheck = false,
        PlayerName = "Name",
        TextSize = 13,
        ShowDistance = true,
        ShowHealth = true,
        ShowName = true,
        UseTeamColor = true,
        MaxDistance = 1000,
        UseMaxDistance = true,
        BOX_WIDTH = 55,
        MIN_BOX_HEIGHT = 25,
        MIN_BOX_WIDTH = 30,
        HP_BAR_WIDTH = 2,
        HP_BAR_OFFSET = 5,
        SMOOTH_FACTOR = 0.6,
        USE_GRADIENT = true,
    }
end

function ESP:lerp(current, target, factor)
    if current == nil then return target end
    return current + (target - current) * factor
end

function ESP:isPlayerVisible(character)
    local head = character:FindFirstChild("Head")
    if not head then return false end
    
    local localChar = self.LocalPlayer.Character
    if not localChar or not localChar:FindFirstChild("Head") then return false end
    
    local rayOrigin = localChar.Head.Position
    local rayDirection = (head.Position - rayOrigin).Unit * 1000
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {self.LocalPlayer.Character}
    
    local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if raycastResult and raycastResult.Instance:IsDescendantOf(character) then
        return true
    end
    
    return false
end

function ESP:createDrawingESP()
    local esp = {}
    
    esp.top = Drawing.new("Line")
    esp.bottom = Drawing.new("Line")
    esp.left = Drawing.new("Line")
    esp.right = Drawing.new("Line")
    esp.hpBg = Drawing.new("Square")
    esp.hpFill = Drawing.new("Square")
    esp.nameText = Drawing.new("Text")
    esp.distText = Drawing.new("Text")
    esp.weaponText = Drawing.new("Text")
    esp.healthText = Drawing.new("Text")
    
    esp.top.Visible = false
    esp.top.Thickness = 1.5
    esp.top.Transparency = 1
    
    esp.bottom.Visible = false
    esp.bottom.Thickness = 1.5
    esp.bottom.Transparency = 1
    
    esp.left.Visible = false
    esp.left.Thickness = 1.5
    esp.left.Transparency = 1
    
    esp.right.Visible = false
    esp.right.Thickness = 1.5
    esp.right.Transparency = 1
    
    esp.hpBg.Visible = false
    esp.hpBg.Color = Color3.fromRGB(20, 20, 20)
    esp.hpBg.Filled = true
    esp.hpBg.Transparency = 0.8
    
    esp.hpFill.Visible = false
    esp.hpFill.Filled = true
    esp.hpFill.Transparency = 1
    
    local textSize = self.ESPEnv.Settings.TextSize
    
    esp.nameText.Visible = false
    esp.nameText.Size = textSize
    esp.nameText.Center = true
    esp.nameText.Outline = true
    esp.nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.nameText.Font = 2
    
    esp.distText.Visible = false
    esp.distText.Size = textSize - 1
    esp.distText.Center = true
    esp.distText.Outline = true
    esp.distText.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.distText.Font = 2
    
    esp.weaponText.Visible = false
    esp.weaponText.Size = textSize - 2
    esp.weaponText.Center = true
    esp.weaponText.Outline = true
    esp.weaponText.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.weaponText.Color = Color3.fromRGB(255, 200, 100)
    esp.weaponText.Font = 2
    
    esp.healthText.Visible = false
    esp.healthText.Size = textSize - 2
    esp.healthText.Center = true
    esp.healthText.Outline = true
    esp.healthText.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.healthText.Font = 2
    
    esp.smoothCenterX = nil
    esp.smoothTopY = nil
    esp.smoothBottomY = nil
    esp.smoothBoxHeight = nil
    esp.smoothBoxWidth = nil
    esp.currentYOffset = 0
    
    return esp
end

function ESP:hideDrawingESP(esp)
    if not esp then return end
    esp.top.Visible = false
    esp.bottom.Visible = false
    esp.left.Visible = false
    esp.right.Visible = false
    esp.hpBg.Visible = false
    esp.hpFill.Visible = false
    esp.nameText.Visible = false
    esp.distText.Visible = false
    esp.weaponText.Visible = false
    esp.healthText.Visible = false
end

function ESP:removeDrawingESP(esp)
    if not esp then return end
    pcall(function() esp.top:Remove() end)
    pcall(function() esp.bottom:Remove() end)
    pcall(function() esp.left:Remove() end)
    pcall(function() esp.right:Remove() end)
    pcall(function() esp.hpBg:Remove() end)
    pcall(function() esp.hpFill:Remove() end)
    pcall(function() esp.nameText:Remove() end)
    pcall(function() esp.distText:Remove() end)
    pcall(function() esp.weaponText:Remove() end)
    pcall(function() esp.healthText:Remove() end)
end

function ESP:getHeightBounds(character)
    local head = character:FindFirstChild("Head")
    if not head then return nil end
    
    local top3D = head.Position + Vector3.new(0, 0.5, 0)
    
    local bottom3D = nil
    local leftFoot = character:FindFirstChild("LeftFoot") or character:FindFirstChild("LeftLeg")
    local rightFoot = character:FindFirstChild("RightFoot") or character:FindFirstChild("RightLeg")
    
    if leftFoot and rightFoot then
        bottom3D = (leftFoot.Position + rightFoot.Position) / 2
    elseif character:FindFirstChild("HumanoidRootPart") then
        local root = character.HumanoidRootPart
        bottom3D = root.Position - Vector3.new(0, 2, 0)
    end
    
    if not bottom3D then return nil end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local center3D = rootPart and rootPart.Position or (top3D + bottom3D) / 2
    
    local top2D, topOnScreen = self.Camera:WorldToViewportPoint(top3D)
    local bottom2D, bottomOnScreen = self.Camera:WorldToViewportPoint(bottom3D)
    local center2D, centerOnScreen = self.Camera:WorldToViewportPoint(center3D)
    
    if not topOnScreen and not bottomOnScreen and not centerOnScreen then
        return nil
    end
    
    local distance = 1
    local localChar = self.LocalPlayer.Character
    if localChar and localChar:FindFirstChild("HumanoidRootPart") and rootPart then
        distance = (localChar.HumanoidRootPart.Position - rootPart.Position).Magnitude
    end
    
    return {
        centerX = center2D.X,
        topY = top2D.Y,
        bottomY = bottom2D.Y,
        height = math.abs(bottom2D.Y - top2D.Y),
        distance = distance,
    }
end

function ESP:getPlayerWeapon(character)
    local tool = character:FindFirstChildOfClass("Tool")
    if tool then
        return tool.Name
    end
    return ""
end

function ESP:getBoxColor(ratio, timeOffset)
    local pulse = math.sin(self.globalTime * 2 + timeOffset) * 0.15
    local r = math.clamp(0 + 180 * ratio + pulse * 30, 0, 255)
    local g = math.clamp(150 * (1 - ratio) + pulse * 20, 0, 255)
    local b = 255
    return Color3.fromRGB(r, g, b)
end

function ESP:getHPColor(healthRatio)
    local r = 255
    local g = 255
    local b = 30
    
    if healthRatio > 0.6 then
        r = math.clamp(255 * (1 - healthRatio) * 2.5, 0, 255)
    elseif healthRatio > 0.3 then
        g = math.clamp(255 * (1 - (0.6 - healthRatio) * 3.3), 0, 255)
    else
        g = math.clamp(255 * healthRatio * 3.3, 0, 100)
    end
    
    return Color3.fromRGB(r, g, b)
end

function ESP:calculateDynamicWidth(height, distance)
    local baseWidth = math.max(self.ESPEnv.Settings.BOX_WIDTH, height * 0.7)
    local distanceScale = math.clamp(50 / math.max(distance, 1), 0.5, 1.5)
    return baseWidth * distanceScale
end

function ESP:UpdateESP()
    local settings = self.ESPEnv.Settings
    self.globalTime = self.globalTime + 0.016
    local smoothFactor = math.min(settings.SMOOTH_FACTOR * 0.016 * 60, 1.0)
    
    local activePlayers = {}
    local playerDataList = {}
    
    for _, player in ipairs(self.Players:GetPlayers()) do
        if player == self.LocalPlayer then continue end
        activePlayers[player] = true
        
        local character = player.Character
        if not character then
            self:hideDrawingESP(self.playerESP[player])
            continue
        end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then
            self:hideDrawingESP(self.playerESP[player])
            continue
        end
        
        local shouldShow = true
        local localHRP = self.LocalPlayer.Character and self.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        local targetHRP = character:FindFirstChild("HumanoidRootPart")
        
        if localHRP and targetHRP then
            local distance = (localHRP.Position - targetHRP.Position).Magnitude
            
            if settings.UseMaxDistance and distance > settings.MaxDistance then
                shouldShow = false
            end
            
            if settings.TeamCheck and player.Team == self.LocalPlayer.Team then
                shouldShow = false
            end
        end
        
        if not shouldShow then
            self:hideDrawingESP(self.playerESP[player])
            continue
        end
        
        if not self.playerESP[player] then
            self.playerESP[player] = self:createDrawingESP()
        end
        
        local bounds = self:getHeightBounds(character)
        if bounds then
            local data = {}
            data.player = player
            data.character = character
            data.humanoid = humanoid
            data.bounds = bounds
            table.insert(playerDataList, data)
        else
            self:hideDrawingESP(self.playerESP[player])
        end
    end
    
    table.sort(playerDataList, function(a, b)
        return a.bounds.distance < b.bounds.distance
    end)
    
    local occupiedZones = {}
    
    for _, data in ipairs(playerDataList) do
        local bounds = data.bounds
        local topY = bounds.topY
        local bottomY = bounds.bottomY
        local centerX = bounds.centerX
        local yOffset = 0
        
        for _, zone in ipairs(occupiedZones) do
            local horizontalOverlap = math.abs(centerX - zone.centerX) < 120
            if horizontalOverlap then
                local adjustedTop = topY + yOffset
                local adjustedBottom = bottomY + yOffset
                if not (adjustedBottom < zone.top or adjustedTop > zone.bottom) then
                    yOffset = zone.bottom - topY + 15
                end
            end
        end
        
        data.yOffset = yOffset
        
        local zone = {}
        zone.top = topY + yOffset
        zone.bottom = bottomY + yOffset
        zone.centerX = centerX
        table.insert(occupiedZones, zone)
    end
    
    for _, data in ipairs(playerDataList) do
        local player = data.player
        local character = data.character
        local humanoid = data.humanoid
        local bounds = data.bounds
        local targetYOffset = data.yOffset
        
        local esp = self.playerESP[player]
        if not esp then continue end
        
        esp.currentYOffset = self:lerp(esp.currentYOffset, targetYOffset, smoothFactor)
        local yOffset = esp.currentYOffset
        
        if esp.smoothCenterX == nil then
            esp.smoothCenterX = bounds.centerX
            esp.smoothTopY = bounds.topY
            esp.smoothBottomY = bounds.bottomY
            esp.smoothBoxHeight = bounds.height
            esp.smoothBoxWidth = self:calculateDynamicWidth(bounds.height, bounds.distance)
        end
        
        esp.smoothCenterX = self:lerp(esp.smoothCenterX, bounds.centerX, smoothFactor)
        esp.smoothTopY = self:lerp(esp.smoothTopY, bounds.topY + yOffset, smoothFactor)
        esp.smoothBottomY = self:lerp(esp.smoothBottomY, bounds.bottomY + yOffset, smoothFactor)
        esp.smoothBoxHeight = self:lerp(esp.smoothBoxHeight, bounds.height, smoothFactor)
        
        local targetWidth = self:calculateDynamicWidth(bounds.height, bounds.distance)
        esp.smoothBoxWidth = self:lerp(esp.smoothBoxWidth or targetWidth, targetWidth, smoothFactor)
        
        local boxHeight = math.max(esp.smoothBoxHeight, settings.MIN_BOX_HEIGHT)
        local boxWidth = math.max(esp.smoothBoxWidth, settings.MIN_BOX_WIDTH)
        
        local topY = esp.smoothTopY
        local bottomY = esp.smoothBottomY
        
        if math.abs((bottomY - topY) - boxHeight) > 5 then
            bottomY = topY + boxHeight
        end
        
        local halfWidth = boxWidth / 2
        local leftX = esp.smoothCenterX - halfWidth
        local rightX = esp.smoothCenterX + halfWidth
        
        local visible = self:isPlayerVisible(character)
        local COLOR_VISIBLE = Color3.fromRGB(0, 255, 0)
        local COLOR_HIDDEN = Color3.fromRGB(255, 50, 50)
        local boxColor = visible and COLOR_VISIBLE or COLOR_HIDDEN
        
        -- Рамка
        if settings.USE_GRADIENT then
            esp.top.Color = self:getBoxColor(0.1, 0)
            esp.bottom.Color = self:getBoxColor(0.9, 1)
            esp.left.Color = self:getBoxColor(0.25, 0.5)
            esp.right.Color = self:getBoxColor(0.75, 1.5)
        else
            esp.top.Color = boxColor
            esp.bottom.Color = boxColor
            esp.left.Color = boxColor
            esp.right.Color = boxColor
        end
        
        esp.top.From = Vector2.new(leftX, topY)
        esp.top.To = Vector2.new(rightX, topY)
        esp.top.Visible = true
        
        esp.bottom.From = Vector2.new(leftX, bottomY)
        esp.bottom.To = Vector2.new(rightX, bottomY)
        esp.bottom.Visible = true
        
        esp.left.From = Vector2.new(leftX, topY)
        esp.left.To = Vector2.new(leftX, bottomY)
        esp.left.Visible = true
        
        esp.right.From = Vector2.new(rightX, topY)
        esp.right.To = Vector2.new(rightX, bottomY)
        esp.right.Visible = true
        
        -- HP бар
        if settings.ShowHealth then
            local hpBarX = leftX - settings.HP_BAR_OFFSET - settings.HP_BAR_WIDTH
            local healthRatio = humanoid.Health / humanoid.MaxHealth
            local hpFillHeight = boxHeight * healthRatio
            
            esp.hpBg.Position = Vector2.new(hpBarX, topY)
            esp.hpBg.Size = Vector2.new(settings.HP_BAR_WIDTH, boxHeight)
            esp.hpBg.Visible = true
            
            esp.hpFill.Position = Vector2.new(hpBarX, topY + boxHeight - hpFillHeight)
            esp.hpFill.Size = Vector2.new(settings.HP_BAR_WIDTH, hpFillHeight)
            esp.hpFill.Color = self:getHPColor(healthRatio)
            esp.hpFill.Visible = true
        end
        
        -- Имя
        if settings.ShowName then
            esp.nameText.Text = player[settings.PlayerName] or player.Name
            esp.nameText.Color = settings.UseTeamColor and player.TeamColor.Color or boxColor
            esp.nameText.Position = Vector2.new(esp.smoothCenterX, topY - 18)
            esp.nameText.Size = settings.TextSize
            esp.nameText.Visible = true
        end
        
        -- Здоровье текстом
        if settings.ShowHealth then
            esp.healthText.Text = string.format("%d HP", math.floor(humanoid.Health))
            esp.healthText.Color = boxColor
            esp.healthText.Position = Vector2.new(esp.smoothCenterX, topY - 32)
            esp.healthText.Size = settings.TextSize - 2
            esp.healthText.Visible = true
        end
        
        -- Оружие
        local weaponName = self:getPlayerWeapon(character)
        if weaponName ~= "" then
            esp.weaponText.Text = weaponName
            esp.weaponText.Position = Vector2.new(esp.smoothCenterX, bottomY + 18)
            esp.weaponText.Size = settings.TextSize - 2
            esp.weaponText.Visible = true
        else
            esp.weaponText.Visible = false
        end
        
        -- Дистанция
        if settings.ShowDistance then
            local distance = math.floor(bounds.distance * 0.28 * 10) / 10
            esp.distText.Text = string.format("%.1f m", distance)
            esp.distText.Color = boxColor
            esp.distText.Position = Vector2.new(esp.smoothCenterX, bottomY + 4)
            esp.distText.Size = settings.TextSize - 1
            esp.distText.Visible = true
        end
    end
    
    for player, esp in pairs(self.playerESP) do
        if not activePlayers[player] then
            self:removeDrawingESP(esp)
            self.playerESP[player] = nil
        end
    end
end

function ESP:RemoveESP()
    for _, esp in pairs(self.playerESP) do
        self:removeDrawingESP(esp)
    end
    self.playerESP = {}
end

function ESP:StartESP()
    self.Active = true
    task.spawn(function()
        while self.Active and self.ESPEnv.Settings.Enabled do
            if not self.ESP_DB then
                self.ESP_DB = true
                pcall(function()
                    self:UpdateESP()
                end)
                self.ESP_DB = false
            end
            task.wait()
        end
    end)
end

function ESP:StopESP()
    self.Active = false
    self.ESPEnv.Settings.Enabled = false
    self:RemoveESP()
end

function ESP:CreateUI(Tab)
    local Settings = Tab:AddLeftGroupbox("ESP Settings")
    local Visuals = Tab:AddRightGroupbox("ESP Visuals")
    
    Settings:AddToggle("DeepESPEnabled", {
        Text = "Enabled",
        Default = false,
        Callback = function(v) 
            self.ESPEnv.Settings.Enabled = v
            if v then
                self:StartESP()
            else
                self:StopESP()
            end
        end
    })
    
    Settings:AddToggle("ESPTeamCheck", {
        Text = "Team Check",
        Default = false,
        Callback = function(v) 
            self.ESPEnv.Settings.TeamCheck = v
            self:RemoveESP()
        end
    })
    
    Settings:AddToggle("ESPShowName", {
        Text = "Show Name",
        Default = true,
        Callback = function(v) 
            self.ESPEnv.Settings.ShowName = v
        end
    })
    
    Settings:AddToggle("ESPShowHealth", {
        Text = "Show Health",
        Default = true,
        Callback = function(v) 
            self.ESPEnv.Settings.ShowHealth = v
        end
    })
    
    Settings:AddToggle("ESPShowDistance", {
        Text = "Show Distance",
        Default = true,
        Callback = function(v) 
            self.ESPEnv.Settings.ShowDistance = v
        end
    })
    
    Settings:AddDropdown("ESPPlayerName", {
        Values = {"Name", "DisplayName"},
        Default = "Name",
        Text = "Player Name Type",
        Callback = function(v) self.ESPEnv.Settings.PlayerName = v end
    })
    
    Settings:AddToggle("ESPUseTeamColor", {
        Text = "Use Team Color",
        Default = true,
        Callback = function(v) 
            self.ESPEnv.Settings.UseTeamColor = v
            self:RemoveESP()
        end
    })
    
    Settings:AddToggle("ESPUseMaxDistance", {
        Text = "Limit Max Distance",
        Default = true,
        Callback = function(v) 
            self.ESPEnv.Settings.UseMaxDistance = v
            self:RemoveESP()
        end
    })
    
    Settings:AddSlider("ESPMaxDistance", {
        Text = "Max Distance",
        Default = 1000,
        Min = 100,
        Max = 5000,
        Rounding = 0,
        Suffix = "m",
        Callback = function(v) 
            self.ESPEnv.Settings.MaxDistance = v
            self:RemoveESP()
        end
    })
    
    Visuals:AddSlider("ESPTextSize", {
        Text = "Text Size",
        Default = 13,
        Min = 10,
        Max = 20,
        Callback = function(v) self.ESPEnv.Settings.TextSize = v end
    })
end

function ESP:Cleanup()
    self:StopESP()
end

return ESP
