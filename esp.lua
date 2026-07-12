local ESP = {}
ESP.__index = ESP

function ESP:Initialize(Tab)
    local self = setmetatable({}, ESP)
    
    if not getgenv().DeepESP then
        getgenv().DeepESP = {}
    end
    
    self.ESPEnv = getgenv().DeepESP
    self.Players = game:GetService("Players")
    self.LocalPlayer = self.Players.LocalPlayer
    self.ESP_DB = false
    self.Active = false
    
    self:LoadDefaultSettings()
    self:CreateUI(Tab)
    
    return self
end

function ESP:LoadDefaultSettings()
    self.ESPEnv.Settings = {
        Enabled = false,
        TeamCheck = false,
        PlayerName = "Name",
        FillTransparency = 0.5,
        OutlineTransparency = 0,
        TextSize = 18,
        TextFont = "SciFi",
        ShowDistance = true,
        ShowHealth = true,
        UseTeamColor = true,
        MaxDistance = 10000,
        UseMaxDistance = true
    }
end

function ESP:GetPlayerHealth(player)
    local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")
    if humanoid then
        return math.floor(humanoid.Health), math.floor(humanoid.MaxHealth)
    end
    return 0, 0
end

function ESP:UpdateESP()
    local settings = self.ESPEnv.Settings
    
    for _, player in ipairs(self.Players:GetPlayers()) do
        if player ~= self.LocalPlayer and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            local localHRP = self.LocalPlayer.Character and self.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            if hrp and localHRP then
                local distance = math.floor((localHRP.Position - hrp.Position).magnitude)
                local shouldShow = true
                
                -- Проверка по дистанции
                if settings.UseMaxDistance and distance > settings.MaxDistance then
                    shouldShow = false
                end
                
                -- Проверка по команде
                if settings.TeamCheck and player.Team == self.LocalPlayer.Team then
                    shouldShow = false
                end
                
                if shouldShow then
                    if not player.Character:FindFirstChild("DeepESP_Highlight") then
                        -- Создаем Highlight
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "DeepESP_Highlight"
                        highlight.Adornee = player.Character
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.FillColor = settings.UseTeamColor and player.TeamColor.Color or Color3.fromRGB(255, 255, 255)
                        highlight.FillTransparency = settings.FillTransparency
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.OutlineTransparency = settings.OutlineTransparency
                        highlight.Enabled = settings.Enabled
                        highlight.Parent = player.Character
                        
                        -- Создаем BillboardGui для имени (над головой)
                        local nameBillboard = Instance.new("BillboardGui")
                        nameBillboard.Name = "DeepESP_NameBoard"
                        nameBillboard.AlwaysOnTop = true
                        nameBillboard.Size = UDim2.new(0, 800, 0, 50)
                        nameBillboard.StudsOffset = Vector3.new(0, 3, 0) -- Над головой
                        nameBillboard.Enabled = settings.Enabled
                        nameBillboard.Parent = player.Character
                        
                        local nameLabel = Instance.new("TextLabel")
                        nameLabel.Name = "DeepESP_Name"
                        nameLabel.BackgroundTransparency = 1
                        nameLabel.Size = UDim2.new(1, 0, 1, 0)
                        nameLabel.Font = Enum.Font[settings.TextFont]
                        nameLabel.TextColor3 = settings.UseTeamColor and player.TeamColor.Color or Color3.fromRGB(255, 255, 255)
                        nameLabel.TextSize = settings.TextSize
                        nameLabel.TextWrapped = true
                        nameLabel.Parent = nameBillboard
                        
                        -- Создаем BillboardGui для информации (ниже имени)
                        local infoBillboard = Instance.new("BillboardGui")
                        infoBillboard.Name = "DeepESP_InfoBoard"
                        infoBillboard.AlwaysOnTop = true
                        infoBillboard.Size = UDim2.new(0, 800, 0, 50)
                        infoBillboard.StudsOffset = Vector3.new(0, 2.2, 0) -- Ниже имени
                        infoBillboard.Enabled = settings.Enabled
                        infoBillboard.Parent = player.Character
                        
                        local infoLabel = Instance.new("TextLabel")
                        infoLabel.Name = "DeepESP_Info"
                        infoLabel.BackgroundTransparency = 1
                        infoLabel.Size = UDim2.new(1, 0, 1, 0)
                        infoLabel.Font = Enum.Font[settings.TextFont]
                        infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                        infoLabel.TextSize = settings.TextSize - 2
                        infoLabel.TextWrapped = true
                        infoLabel.Parent = infoBillboard
                    end
                    
                    local highlight = player.Character:FindFirstChild("DeepESP_Highlight")
                    local nameBoard = player.Character:FindFirstChild("DeepESP_NameBoard")
                    local infoBoard = player.Character:FindFirstChild("DeepESP_InfoBoard")
                    
                    if highlight and nameBoard and infoBoard then
                        highlight.Enabled = settings.Enabled
                        nameBoard.Enabled = settings.Enabled
                        infoBoard.Enabled = settings.Enabled
                        
                        -- Обновляем цвета Highlight
                        if settings.UseTeamColor then
                            highlight.FillColor = player.TeamColor.Color
                        else
                            highlight.FillColor = Color3.fromRGB(255, 255, 255)
                        end
                        
                        highlight.FillTransparency = settings.FillTransparency
                        highlight.OutlineTransparency = settings.OutlineTransparency
                        
                        -- Обновляем имя
                        local nameLabel = nameBoard:FindFirstChild("DeepESP_Name")
                        if nameLabel then
                            nameLabel.TextSize = settings.TextSize
                            nameLabel.Font = Enum.Font[settings.TextFont]
                            nameLabel.Text = player[settings.PlayerName] or player.Name
                            
                            if settings.UseTeamColor then
                                nameLabel.TextColor3 = player.TeamColor.Color
                            else
                                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                            end
                        end
                        
                        -- Обновляем информацию (HP и дистанция)
                        local infoLabel = infoBoard:FindFirstChild("DeepESP_Info")
                        if infoLabel then
                            infoLabel.TextSize = settings.TextSize - 2
                            infoLabel.Font = Enum.Font[settings.TextFont]
                            
                            local infoText = ""
                            
                            -- Добавляем HP
                            if settings.ShowHealth then
                                local health, maxHealth = self:GetPlayerHealth(player)
                                local healthColor = Color3.fromRGB(255, 0, 0) -- Красный по умолчанию
                                
                                if health > maxHealth * 0.6 then
                                    healthColor = Color3.fromRGB(0, 255, 0) -- Зеленый если больше 60%
                                elseif health > maxHealth * 0.3 then
                                    healthColor = Color3.fromRGB(255, 255, 0) -- Желтый если больше 30%
                                end
                                
                                infoLabel.TextColor3 = healthColor
                                infoText = infoText .. "HP " .. health .. "/" .. maxHealth
                            end
                            
                            -- Добавляем дистанцию
                            if settings.ShowDistance then
                                if infoText ~= "" then
                                    infoText = infoText .. " | "
                                end
                                
                                if distance >= 1000 then
                                    infoText = infoText .. string.format("%.1f", distance/1000) .. "km"
                                else
                                    infoText = infoText .. distance .. "m"
                                end
                                
                                -- Если HP не показывается, используем белый цвет для дистанции
                                if not settings.ShowHealth then
                                    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                                end
                            end
                            
                            infoLabel.Text = infoText
                        end
                    end
                else
                    -- Удаляем ESP для игроков за пределами дистанции
                    local highlight = player.Character:FindFirstChild("DeepESP_Highlight")
                    local nameBoard = player.Character:FindFirstChild("DeepESP_NameBoard")
                    local infoBoard = player.Character:FindFirstChild("DeepESP_InfoBoard")
                    
                    if highlight then highlight:Destroy() end
                    if nameBoard then nameBoard:Destroy() end
                    if infoBoard then infoBoard:Destroy() end
                end
            end
        end
    end
end

function ESP:RemoveESP()
    for _, player in ipairs(self.Players:GetPlayers()) do
        if player.Character then
            local highlight = player.Character:FindFirstChild("DeepESP_Highlight")
            local nameBoard = player.Character:FindFirstChild("DeepESP_NameBoard")
            local infoBoard = player.Character:FindFirstChild("DeepESP_InfoBoard")
            
            if highlight then highlight:Destroy() end
            if nameBoard then nameBoard:Destroy() end
            if infoBoard then infoBoard:Destroy() end
        end
    end
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
    local Main = Tab:AddLeftGroupbox("ESP Settings")
    local Visuals = Tab:AddRightGroupbox("ESP Visuals")
    local Distance = Tab:AddRightGroupbox("Distance Settings")
    
    Main:AddToggle("DeepESPEnabled", {
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
    
    Main:AddToggle("ESPTeamCheck", {
        Text = "Team Check",
        Default = false,
        Callback = function(v) 
            self.ESPEnv.Settings.TeamCheck = v
            self:RemoveESP()
        end
    })
    
    Main:AddDropdown("ESPPlayerName", {
        Values = {"Name", "DisplayName"},
        Default = "Name",
        Text = "Player Name Type",
        Callback = function(v) self.ESPEnv.Settings.PlayerName = v end
    })
    
    Main:AddToggle("ESPShowDistance", {
        Text = "Show Distance",
        Default = true,
        Callback = function(v) self.ESPEnv.Settings.ShowDistance = v end
    })
    
    Main:AddToggle("ESPShowHealth", {
        Text = "Show Health",
        Default = true,
        Callback = function(v) self.ESPEnv.Settings.ShowHealth = v end
    })
    
    Main:AddToggle("ESPUseTeamColor", {
        Text = "Use Team Color",
        Default = true,
        Callback = function(v) 
            self.ESPEnv.Settings.UseTeamColor = v
            self:RemoveESP()
        end
    })
    
    -- Настройки дистанции
    Distance:AddToggle("ESPUseMaxDistance", {
        Text = "Limit Max Distance",
        Default = true,
        Callback = function(v) 
            self.ESPEnv.Settings.UseMaxDistance = v
            self:RemoveESP()
        end
    })
    
    Distance:AddSlider("ESPMaxDistance", {
        Text = "Max Distance (meters)",
        Default = 10000,
        Min = 100,
        Max = 50000,
        Rounding = 0,
        Suffix = "m",
        Callback = function(v) 
            self.ESPEnv.Settings.MaxDistance = v
            self:RemoveESP()
        end
    })
    
    Visuals:AddSlider("ESPFillTransparency", {
        Text = "Fill Transparency",
        Default = 0.5,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) self.ESPEnv.Settings.FillTransparency = v end
    })
    
    Visuals:AddSlider("ESPOutlineTransparency", {
        Text = "Outline Transparency",
        Default = 0,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) self.ESPEnv.Settings.OutlineTransparency = v end
    })
    
    Visuals:AddSlider("ESPTextSize", {
        Text = "Text Size",
        Default = 18,
        Min = 10,
        Max = 30,
        Callback = function(v) self.ESPEnv.Settings.TextSize = v end
    })
    
    Visuals:AddDropdown("ESPTextFont", {
        Values = {"SciFi", "Arial", "Fantasy", "Gotham", "Legacy", "SourceSans"},
        Default = "SciFi",
        Text = "Text Font",
        Callback = function(v) self.ESPEnv.Settings.TextFont = v end
    })
end

function ESP:Cleanup()
    self:StopESP()
end

return ESP
