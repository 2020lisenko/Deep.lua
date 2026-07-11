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
        UseTeamColor = true,
    }
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
                
                if settings.TeamCheck and player.Team == self.LocalPlayer.Team then
                    shouldShow = false
                end
                
                if shouldShow then
                    if not player.Character:FindFirstChild("DeepESP_Highlight") then
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
                        
                        local billboard = Instance.new("BillboardGui")
                        billboard.Name = "DeepESP_Icon"
                        billboard.AlwaysOnTop = true
                        billboard.Size = UDim2.new(0, 800, 0, 50)
                        billboard.Enabled = settings.Enabled
                        billboard.Parent = player.Character
                        
                        local textLabel = Instance.new("TextLabel")
                        textLabel.Name = "DeepESP_Text"
                        textLabel.BackgroundTransparency = 1
                        textLabel.Size = UDim2.new(0, 800, 0, 50)
                        textLabel.Font = Enum.Font[settings.TextFont]
                        textLabel.TextColor3 = settings.UseTeamColor and player.TeamColor.Color or Color3.fromRGB(255, 255, 255)
                        textLabel.TextSize = settings.TextSize
                        textLabel.TextWrapped = true
                        textLabel.Parent = billboard
                    end
                    
                    local highlight = player.Character:FindFirstChild("DeepESP_Highlight")
                    local icon = player.Character:FindFirstChild("DeepESP_Icon")
                    
                    if highlight and icon then
                        highlight.Enabled = settings.Enabled
                        icon.Enabled = settings.Enabled
                        
                        if settings.UseTeamColor then
                            highlight.FillColor = player.TeamColor.Color
                            icon["DeepESP_Text"].TextColor3 = player.TeamColor.Color
                        end
                        
                        highlight.FillTransparency = settings.FillTransparency
                        highlight.OutlineTransparency = settings.OutlineTransparency
                        icon["DeepESP_Text"].TextSize = settings.TextSize
                        icon["DeepESP_Text"].Font = Enum.Font[settings.TextFont]
                        
                        local text = player[settings.PlayerName]
                        if settings.ShowDistance then
                            text = text .. " | Distance: " .. distance
                        end
                        icon["DeepESP_Text"].Text = text
                    end
                end
            end
        end
    end
end

function ESP:RemoveESP()
    for _, player in ipairs(self.Players:GetPlayers()) do
        if player.Character then
            local highlight = player.Character:FindFirstChild("DeepESP_Highlight")
            local icon = player.Character:FindFirstChild("DeepESP_Icon")
            
            if highlight then highlight:Destroy() end
            if icon then icon:Destroy() end
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
    
    Main:AddToggle("ESPUseTeamColor", {
        Text = "Use Team Color",
        Default = true,
        Callback = function(v) 
            self.ESPEnv.Settings.UseTeamColor = v
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
