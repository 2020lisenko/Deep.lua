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
    
    -- Сохраняем состояние пост-эффектов
    self.DefaultPostEffects = {}
    for _, effect in ipairs({"Bloom", "Blur", "ColorCorrection", "SunRays"}) do
        local e = self.Lighting:FindFirstChild(effect)
        if e then
            self.DefaultPostEffects[effect] = e.Enabled
        end
    end
    
    self:LoadDefaultSettings()
    self:CreateUI(Tab)
    self:StartVisualLoop()
    
    return self
end

function Visuals:LoadDefaultSettings()
    self.VisualsEnv.Settings = {
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
        SkyboxEnabled = false,
        SkyboxId = ""
    }
end

function Visuals:ApplySettings()
    local settings = self.VisualsEnv.Settings
    
    -- FullBright
    if settings.FullBright then
        self.Lighting.Brightness = 2
        self.Lighting.ClockTime = 14
        self.Lighting.FogEnd = 100000
        self.Lighting.GlobalShadows = false
        self.Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    else
        self.Lighting.Brightness = self.DefaultSettings.Brightness
        if not settings.CustomTime then
            self.Lighting.ClockTime = self.DefaultSettings.ClockTime
        end
        if not settings.NoFog then
            self.Lighting.FogEnd = self.DefaultSettings.FogEnd
        end
        if not settings.NoShadows then
            self.Lighting.GlobalShadows = self.DefaultSettings.GlobalShadows
        end
        if not settings.CustomAmbient then
            self.Lighting.OutdoorAmbient = self.DefaultSettings.OutdoorAmbient
        end
    end
    
    -- NoFog
    if settings.NoFog then
        self.Lighting.FogEnd = 100000
        self.Lighting.FogStart = 100000
    else
        self.Lighting.FogEnd = self.DefaultSettings.FogEnd
        self.Lighting.FogStart = self.DefaultSettings.FogStart
    end
    
    -- NoShadows
    if settings.NoShadows then
        self.Lighting.GlobalShadows = false
    else
        self.Lighting.GlobalShadows = self.DefaultSettings.GlobalShadows
    end
    
    -- CustomTime
    if settings.CustomTime then
        self.Lighting.ClockTime = settings.CustomTimeValue
    else
        self.Lighting.ClockTime = self.DefaultSettings.ClockTime
    end
    
    -- CustomBrightness
    if settings.CustomBrightness then
        self.Lighting.Brightness = settings.BrightnessValue
    else
        if not settings.FullBright then
            self.Lighting.Brightness = self.DefaultSettings.Brightness
        end
    end
    
    -- CustomAmbient
    if settings.CustomAmbient then
        self.Lighting.OutdoorAmbient = settings.AmbientColor
    else
        if not settings.FullBright then
            self.Lighting.OutdoorAmbient = self.DefaultSettings.OutdoorAmbient
        end
    end
    
    -- CustomExposure
    if settings.CustomExposure then
        self.Lighting.ExposureCompensation = settings.ExposureValue
    else
        self.Lighting.ExposureCompensation = self.DefaultSettings.ExposureCompensation
    end
    
    -- Пост-обработка
    self:TogglePostEffect("Bloom", not settings.DisableBloom)
    self:TogglePostEffect("Blur", not settings.DisableBlur)
    self:TogglePostEffect("ColorCorrection", not settings.DisableColorCorrection)
    self:TogglePostEffect("SunRays", not settings.DisableSunRays)
    
    -- Skybox
    if settings.SkyboxEnabled and settings.SkyboxId ~= "" then
        self:ApplySkybox(settings.SkyboxId)
    else
        self:RemoveSkybox()
    end
end

function Visuals:TogglePostEffect(effectName, enabled)
    local effect = self.Lighting:FindFirstChild(effectName)
    if effect then
        effect.Enabled = enabled
    end
end

function Visuals:ApplySkybox(skyboxId)
    self:RemoveSkybox()
    local sky = Instance.new("Sky")
    sky.Name = "DeepCustomSky"
    sky.SkyboxBk = skyboxId
    sky.SkyboxDn = skyboxId
    sky.SkyboxFt = skyboxId
    sky.SkyboxLf = skyboxId
    sky.SkyboxRt = skyboxId
    sky.SkyboxUp = skyboxId
    sky.Parent = self.Lighting
end

function Visuals:RemoveSkybox()
    for _, child in ipairs(self.Lighting:GetChildren()) do
        if child:IsA("Sky") and child.Name == "DeepCustomSky" then
            child:Destroy()
        end
    end
end

function Visuals:RestoreDefaults()
    self.Lighting.Brightness = self.DefaultSettings.Brightness
    self.Lighting.FogEnd = self.DefaultSettings.FogEnd
    self.Lighting.FogStart = self.DefaultSettings.FogStart
    self.Lighting.GlobalShadows = self.DefaultSettings.GlobalShadows
    self.Lighting.OutdoorAmbient = self.DefaultSettings.OutdoorAmbient
    self.Lighting.ClockTime = self.DefaultSettings.ClockTime
    self.Lighting.ExposureCompensation = self.DefaultSettings.ExposureCompensation
    
    -- Восстанавливаем пост-эффекты
    for effectName, enabled in pairs(self.DefaultPostEffects) do
        self:TogglePostEffect(effectName, enabled)
    end
    
    self:RemoveSkybox()
end

function Visuals:StartVisualLoop()
    self.Connections.RenderStepped = self.RunService.RenderStepped:Connect(function()
        self:ApplySettings()
    end)
end

function Visuals:CreateUI(Tab)
    local Lighting = Tab:AddLeftGroupbox("Lighting Settings")
    local PostProcessing = Tab:AddRightGroupbox("Post Processing")
    local Skybox = Tab:AddLeftGroupbox("Skybox")
    
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
    
    Lighting:AddDivider()
    
    -- Кнопка сброса
    Lighting:AddButton("Restore Defaults", function()
        -- Сбрасываем все настройки
        self.VisualsEnv.Settings = {
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
            SkyboxEnabled = false,
            SkyboxId = ""
        }
        
        self:RestoreDefaults()
        
        -- Обновляем UI (Library сама обновит значения)
        print("Visuals restored to defaults")
    end)
    
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
    
    -- Skybox
    Skybox:AddToggle("SkyboxEnabled", {
        Text = "Custom Skybox",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.SkyboxEnabled = v end
    })
    
    Skybox:AddDropdown("SkyboxId", {
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
