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
        ShowName = true,
        UseTeamColor = true,
        MaxDistance = 10000,
        UseMaxDistance = true,
        DisplayMode = "All" -- "All", "NameOnly", "InfoOnly", "Custom"
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
                        
                        -- Создаем BillboardGui для всего текста
                        local billboard = Instance.new("BillboardGui")
                        billboard.Name = "DeepESP_Board"
                        billboard.AlwaysOnTop = true
                        billboard.Size = UDim2.new(0, 800, 0, 100)
                        billboard.StudsOffset = Vector3.new(0, 3, 0)
                        billboard.Enabled = settings.Enabled
                        billboard.Parent = player.Character
                        
                        -- Имя (сверху)
                        local nameLabel = Instance.new("TextLabel")
                        nameLabel.Name = "DeepESP_Name"
                        nameLabel.BackgroundTransparency = 1
                        nameLabel.Size = UDim2.new(1, 0, 0, 30)
                        nameLabel.Position = UDim2.new(0, 0, 0, 0)
                        nameLabel.Font = Enum.Font[settings.TextFont]
                        nameLabel.TextColor3 = settings.UseTeamColor and player.TeamColor.Color or Color3.fromRGB(255, 255, 255)
                        nameLabel.TextSize = settings.TextSize
                        nameLabel.TextWrapped = true
                        nameLabel.Parent = billboard
                        
                        -- Информация HP и дистанция (снизу)
                        local infoLabel = Instance.new("TextLabel")
                        infoLabel.Name = "DeepESP_Info"
                        infoLabel.BackgroundTransparency = 1
                        infoLabel.Size = UDim2.new(1, 0, 0, 20)
                        infoLabel.Position = UDim2.new(0, 0, 0, 35)
                        infoLabel.Font = Enum.Font[settings.TextFont]
                        infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                        infoLabel.TextSize = settings.TextSize - 2
                        infoLabel.TextWrapped = true
                        infoLabel.Parent = billboard
                    end
                    
                    local highlight = player.Character:FindFirstChild("DeepESP_Highlight")
                    local board = player.Character:FindFirstChild("DeepESP_Board")
                    
                    if highlight and board then
                        highlight.Enabled = settings.Enabled
                        board.Enabled = settings.Enabled
                        
                        -- Обновляем цвета Highlight
                        if settings.UseTeamColor then
                            highlight.FillColor = player.TeamColor.Color
                        else
                            highlight.FillColor = Color3.fromRGB(255, 255, 255)
                        end
                        
                        highlight.FillTransparency = settings.FillTransparency
                        highlight.OutlineTransparency = settings.OutlineTransparency
                        
                        -- Обновляем имя
                        local nameLabel = board:FindFirstChild("DeepESP_Name")
                        if nameLabel then
                            nameLabel.TextSize = settings.TextSize
                            nameLabel.Font = Enum.Font[settings.TextFont]
                            
                            -- Показываем или скрываем имя в зависимости от настроек
                            if settings.ShowName then
                                nameLabel.Visible = true
                                nameLabel.Text = player[settings.PlayerName] or player.Name
                                
                                if settings.UseTeamColor then
                                    nameLabel.TextColor3 = player.TeamColor.Color
                                else
                                    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                                end
                            else
                                nameLabel.Visible = false
                            end
                        end
                        
                        -- Обновляем информацию (HP и дистанция)
                        local infoLabel = board:FindFirstChild("DeepESP_Info")
                        if infoLabel then
                            infoLabel.TextSize = settings.TextSize - 2
                            infoLabel.Font = Enum.Font[settings.TextFont]
                            
                            local infoParts = {}
                            local showInfo = false
                            
                            -- Добавляем HP
                            if settings.ShowHealth then
                                local health, maxHealth = self:GetPlayerHealth(player)
                                
                                -- Определяем цвет для HP
                                if health > maxHealth * 0.6 then
                                    infoLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Зеленый
                                elseif health > maxHealth * 0.3 then
                                    infoLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- Желтый
                                else
                                    infoLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Красный
                                end
                                
                                table.insert(infoParts, "HP " .. health .. "/" .. maxHealth)
                                showInfo = true
                            end
                            
                            -- Добавляем дистанцию
                            if settings.ShowDistance then
                                local distText
                                if distance >= 1000 then
                                    distText = string.format("%.1f", distance/1000) .. "km"
                                else
                                    distText = distance .. "m"
                                end
                                table.insert(infoParts, distText)
                                showInfo = true
                                
                                -- Если HP не показывается, используем серый цвет
                                if not settings.ShowHealth then
                                    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
                                end
                            end
                            
                            -- Показываем или скрываем информацию
                            if showInfo then
                                infoLabel.Visible = true
                                infoLabel.Text = table.concat(infoParts, " | ")
                            else
                                infoLabel.Visible = false
                            end
                        end
                    end
                else
                    -- Удаляем ESP для игроков за пределами дистанции
                    local highlight = player.Character:FindFirstChild("DeepESP_Highlight")
                    local board = player.Character:FindFirstChild("DeepESP_Board")
                    
                    if highlight then highlight:Destroy() end
                    if board then board:Destroy() end
                end
            end
        end
    end
end

function ESP:RemoveESP()
    for _, player in ipairs(self.Players:GetPlayers()) do
        if player.Character then
            local highlight = player.Character:FindFirstChild("DeepESP_Highlight")
            local board = player.Character:FindFirstChild("DeepESP_Board")
            
            if highlight then highlight:Destroy() end
            if board then board:Destroy() end
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
    local Settings = Tab:AddLeftGroupbox("ESP Settings")
    local Visuals = Tab:AddRightGroupbox("ESP Visuals")
    
    -- Основные настройки
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
    
    -- Режим отображения
    Settings:AddDropdown("ESPDisplayMode", {
        Values = {"All", "Name Only", "Info Only", "Custom"},
        Default = "All",
        Text = "Display Mode",
        Callback = function(v) 
            self.ESPEnv.Settings.DisplayMode = v
            if v == "All" then
                self.ESPEnv.Settings.ShowName = true
                self.ESPEnv.Settings.ShowHealth = true
                self.ESPEnv.Settings.ShowDistance = true
            elseif v == "Name Only" then
                self.ESPEnv.Settings.ShowName = true
                self.ESPEnv.Settings.ShowHealth = false
                self.ESPEnv.Settings.ShowDistance = false
            elseif v == "Info Only" then
                self.ESPEnv.Settings.ShowName = false
                self.ESPEnv.Settings.ShowHealth = true
                self.ESPEnv.Settings.ShowDistance = true
            end
            self:RemoveESP()
        end
    })
    
    -- Кастомные настройки (активны только в режиме Custom)
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
    
    -- Настройки дистанции (теперь в основном блоке)
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
    
    -- Визуальные настройки
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
