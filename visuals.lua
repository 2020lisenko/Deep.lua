local Visuals = {}
Visuals.__index = Visuals

function Visuals:Initialize(Tab)
    local self = setmetatable({}, Visuals)
    
    if not getgenv().DeepVisuals then
        getgenv().DeepVisuals = {}
    end
    
    self.VisualsEnv = getgenv().DeepVisuals
    self.Connections = {}
    
    -- Сервисы
    self.Lighting = game:GetService("Lighting")
    self.RunService = game:GetService("RunService")
    self.Players = game:GetService("Players")
    self.LocalPlayer = self.Players.LocalPlayer
    
    -- Сохранение оригинальных значений
    self.DefaultSettings = {
        Brightness = self.Lighting.Brightness,
        FogEnd = self.Lighting.FogEnd,
        FogStart = self.Lighting.FogStart,
        GlobalShadows = self.Lighting.GlobalShadows,
        OutdoorAmbient = self.Lighting.OutdoorAmbient,
        ClockTime = self.Lighting.ClockTime,
        ExposureCompensation = self.Lighting.ExposureCompensation
    }
    
    self:LoadDefaultSettings()
    self:CreateUI(Tab)
    self:StartVisualLoop()
    
    return self
end

function Visuals:LoadDefaultSettings()
    self.VisualsEnv.Settings = {
        Enabled = false,
        FullBright = false,
        NoFog = false,
        NoShadows = false,
        CustomTime = false,
        CustomTimeValue = 12,
        CustomBrightness = false,
        BrightnessValue = 2,
        CustomAmbient = false,
        AmbientColor = Color3.fromRGB(255, 255, 255),
        CustomExposure = false,
        ExposureValue = 0,
        DisableBloom = false,
        DisableBlur = false,
        DisableColorCorrection = false,
        DisableSunRays = false,
        ChamsEnabled = false,
        ChamsColor = Color3.fromRGB(255, 0, 0),
        ChamsTransparency = 0.5,
        WireframeEnabled = false,
        WireframeThickness = 0.01,
        SkyboxEnabled = false,
        SkyboxId = ""
    }
end

function Visuals:ApplySettings()
    local settings = self.VisualsEnv.Settings
    
    if not settings.Enabled then
        self:RestoreDefaults()
        return
    end
    
    -- FullBright
    if settings.FullBright then
        self.Lighting.Brightness = 2
        self.Lighting.ClockTime = 14
        self.Lighting.FogEnd = 100000
        self.Lighting.GlobalShadows = false
        self.Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    end
    
    -- NoFog
    if settings.NoFog then
        self.Lighting.FogEnd = 100000
        self.Lighting.FogStart = 100000
    end
    
    -- NoShadows
    if settings.NoShadows then
        self.Lighting.GlobalShadows = false
    end
    
    -- CustomTime
    if settings.CustomTime then
        self.Lighting.ClockTime = settings.CustomTimeValue
    end
    
    -- CustomBrightness
    if settings.CustomBrightness then
        self.Lighting.Brightness = settings.BrightnessValue
    end
    
    -- CustomAmbient
    if settings.CustomAmbient then
        self.Lighting.OutdoorAmbient = settings.AmbientColor
    end
    
    -- CustomExposure
    if settings.CustomExposure then
        self.Lighting.ExposureCompensation = settings.ExposureValue
    end
    
    -- Пост-обработка
    self:TogglePostEffect("Bloom", not settings.DisableBloom)
    self:TogglePostEffect("Blur", not settings.DisableBlur)
    self:TogglePostEffect("ColorCorrection", not settings.DisableColorCorrection)
    self:TogglePostEffect("SunRays", not settings.DisableSunRays)
    
    -- Chams
    if settings.ChamsEnabled then
        self:ApplyChams()
    else
        self:RemoveChams()
    end
    
    -- Wireframe
    if settings.WireframeEnabled then
        self:ApplyWireframe()
    else
        self:RemoveWireframe()
    end
    
    -- Skybox
    if settings.SkyboxEnabled and settings.SkyboxId ~= "" then
        self:ApplySkybox(settings.SkyboxId)
    end
end

function Visuals:TogglePostEffect(effectName, enabled)
    local effect = self.Lighting:FindFirstChild(effectName)
    if effect then
        effect.Enabled = enabled
    end
end

function Visuals:ApplyChams()
    local settings = self.VisualsEnv.Settings
    
    for _, player in ipairs(self.Players:GetPlayers()) do
        if player ~= self.LocalPlayer and player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if not part:FindFirstChild("ChamsHighlight") then
                        local highlight = Instance.new("Highlight")
                        highlight.Name = "ChamsHighlight"
                        highlight.FillColor = settings.ChamsColor
                        highlight.FillTransparency = settings.ChamsTransparency
                        highlight.OutlineColor = settings.ChamsColor
                        highlight.OutlineTransparency = 0
                        highlight.Adornee = part
                        highlight.Parent = part
                    end
                end
            end
        end
    end
end

function Visuals:RemoveChams()
    for _, player in ipairs(self.Players:GetPlayers()) do
        if player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                local highlight = part:FindFirstChild("ChamsHighlight")
                if highlight then
                    highlight:Destroy()
                end
            end
        end
    end
end

function Visuals:ApplyWireframe()
    local settings = self.VisualsEnv.Settings
    
    for _, player in ipairs(self.Players:GetPlayers()) do
        if player ~= self.LocalPlayer and player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                if part:IsA("BasePart") and not part:FindFirstChild("WireframeHighlight") then
                    local highlight = Instance.new("SelectionBox")
                    highlight.Name = "WireframeHighlight"
                    highlight.LineThickness = settings.WireframeThickness
                    highlight.Color3 = settings.ChamsColor
                    highlight.Transparency = 0.5
                    highlight.Adornee = part
                    highlight.Parent = part
                end
            end
        end
    end
end

function Visuals:RemoveWireframe()
    for _, player in ipairs(self.Players:GetPlayers()) do
        if player.Character then
            for _, part in ipairs(player.Character:GetDescendants()) do
                local wireframe = part:FindFirstChild("WireframeHighlight")
                if wireframe then
                    wireframe:Destroy()
                end
            end
        end
    end
end

function Visuals:ApplySkybox(skyboxId)
    local sky = Instance.new("Sky")
    sky.SkyboxBk = skyboxId
    sky.SkyboxDn = skyboxId
    sky.SkyboxFt = skyboxId
    sky.SkyboxLf = skyboxId
    sky.SkyboxRt = skyboxId
    sky.SkyboxUp = skyboxId
    sky.Parent = self.Lighting
end

function Visuals:RestoreDefaults()
    self.Lighting.Brightness = self.DefaultSettings.Brightness
    self.Lighting.FogEnd = self.DefaultSettings.FogEnd
    self.Lighting.FogStart = self.DefaultSettings.FogStart
    self.Lighting.GlobalShadows = self.DefaultSettings.GlobalShadows
    self.Lighting.OutdoorAmbient = self.DefaultSettings.OutdoorAmbient
    self.Lighting.ClockTime = self.DefaultSettings.ClockTime
    self.Lighting.ExposureCompensation = self.DefaultSettings.ExposureCompensation
    
    self:RemoveChams()
    self:RemoveWireframe()
    
    -- Удаление Sky
    for _, child in ipairs(self.Lighting:GetChildren()) do
        if child:IsA("Sky") then
            child:Destroy()
        end
    end
end

function Visuals:StartVisualLoop()
    self.Connections.RenderStepped = self.RunService.RenderStepped:Connect(function()
        if self.VisualsEnv.Settings.Enabled then
            self:ApplySettings()
        end
    end)
end

function Visuals:CreateUI(Tab)
    local Lighting = Tab:AddLeftGroupbox("Lighting Settings")
    local PostProcessing = Tab:AddRightGroupbox("Post Processing")
    local PlayerVisuals = Tab:AddLeftGroupbox("Player Visuals")
    
    -- Main Toggle
    Lighting:AddToggle("VisualsEnabled", {
        Text = "Enabled",
        Default = false,
        Callback = function(v) 
            self.VisualsEnv.Settings.Enabled = v
            if not v then self:RestoreDefaults() end
        end
    })
    
    -- FullBright
    Lighting:AddToggle("FullBright", {
        Text = "Full Bright",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.FullBright = v end
    })
    
    -- NoFog
    Lighting:AddToggle("NoFog", {
        Text = "No Fog",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.NoFog = v end
    })
    
    -- NoShadows
    Lighting:AddToggle("NoShadows", {
        Text = "No Shadows",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.NoShadows = v end
    })
    
    -- CustomTime
    Lighting:AddToggle("CustomTime", {
        Text = "Custom Time",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.CustomTime = v end
    })
    
    Lighting:AddSlider("CustomTimeValue", {
        Text = "Time",
        Default = 12,
        Min = 0,
        Max = 24,
        Rounding = 1,
        Callback = function(v) self.VisualsEnv.Settings.CustomTimeValue = v end
    })
    
    -- CustomBrightness
    Lighting:AddToggle("CustomBrightness", {
        Text = "Custom Brightness",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.CustomBrightness = v end
    })
    
    Lighting:AddSlider("BrightnessValue", {
        Text = "Brightness",
        Default = 2,
        Min = 0,
        Max = 10,
        Rounding = 1,
        Callback = function(v) self.VisualsEnv.Settings.BrightnessValue = v end
    })
    
    -- CustomAmbient
    Lighting:AddToggle("CustomAmbient", {
        Text = "Custom Ambient",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.CustomAmbient = v end
    })
    
    Lighting:AddLabel("Ambient Color"):AddColorPicker("AmbientColor", {
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(v) self.VisualsEnv.Settings.AmbientColor = v end
    })
    
    -- CustomExposure
    Lighting:AddToggle("CustomExposure", {
        Text = "Custom Exposure",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.CustomExposure = v end
    })
    
    Lighting:AddSlider("ExposureValue", {
        Text = "Exposure",
        Default = 0,
        Min = -5,
        Max = 5,
        Rounding = 1,
        Callback = function(v) self.VisualsEnv.Settings.ExposureValue = v end
    })
    
    -- Post Processing
    PostProcessing:AddToggle("DisableBloom", {
        Text = "Disable Bloom",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.DisableBloom = v end
    })
    
    PostProcessing:AddToggle("DisableBlur", {
        Text = "Disable Blur",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.DisableBlur = v end
    })
    
    PostProcessing:AddToggle("DisableColorCorrection", {
        Text = "Disable Color Correction",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.DisableColorCorrection = v end
    })
    
    PostProcessing:AddToggle("DisableSunRays", {
        Text = "Disable Sun Rays",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.DisableSunRays = v end
    })
    
    -- Player Visuals
    PlayerVisuals:AddToggle("ChamsEnabled", {
        Text = "Chams (ESP Overlay)",
        Default = false,
        Callback = function(v) 
            self.VisualsEnv.Settings.ChamsEnabled = v
            if not v then self:RemoveChams() end
        end
    })
    
    PlayerVisuals:AddLabel("Chams Color"):AddColorPicker("ChamsColor", {
        Default = Color3.fromRGB(255, 0, 0),
        Callback = function(v) self.VisualsEnv.Settings.ChamsColor = v end
    })
    
    PlayerVisuals:AddSlider("ChamsTransparency", {
        Text = "Chams Transparency",
        Default = 0.5,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) self.VisualsEnv.Settings.ChamsTransparency = v end
    })
    
    PlayerVisuals:AddToggle("WireframeEnabled", {
        Text = "Wireframe",
        Default = false,
        Callback = function(v) 
            self.VisualsEnv.Settings.WireframeEnabled = v
            if not v then self:RemoveWireframe() end
        end
    })
    
    PlayerVisuals:AddSlider("WireframeThickness", {
        Text = "Wireframe Thickness",
        Default = 0.01,
        Min = 0.005,
        Max = 0.1,
        Rounding = 3,
        Callback = function(v) self.VisualsEnv.Settings.WireframeThickness = v end
    })
    
    -- Skybox
    PlayerVisuals:AddToggle("SkyboxEnabled", {
        Text = "Custom Skybox",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.SkyboxEnabled = v end
    })
    
    PlayerVisuals:AddDropdown("SkyboxId", {
        Values = {
            "rbxassetid://123456789",
            "rbxassetid://987654321",
            "rbxassetid://111111111"
        },
        Default = "",
        Text = "Skybox ID",
        Callback = function(v) self.VisualsEnv.Settings.SkyboxId = v end
    })
end

function Visuals:Cleanup()
    for _, connection in pairs(self.Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    self.Connections = {}
    self:RestoreDefaults()
end

return Visuals
