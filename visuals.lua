local Visuals = {}
Visuals.__index = Visuals

function Visuals:Initialize(Tab)
    local self = setmetatable({}, Visuals)
    
    if not getgenv().DeepVisuals then
        getgenv().DeepVisuals = {}
    end
    
    self.VisualsEnv = getgenv().DeepVisuals
    self.Connections = {}
    self.UIElements = {} -- Для хранения ссылок на UI элементы
    
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
        ExposureCompensation = self.Lighting.ExposureCompensation,
        Ambient = self.Lighting.Ambient,
        ColorShift_Top = self.Lighting.ColorShift_Top,
        ColorShift_Bottom = self.Lighting.ColorShift_Bottom,
        EnvironmentDiffuseScale = self.Lighting.EnvironmentDiffuseScale,
        EnvironmentSpecularScale = self.Lighting.EnvironmentSpecularScale,
        ShadowSoftness = self.Lighting.ShadowSoftness
    }
    
    -- Сохраняем состояние пост-эффектов
    self.DefaultPostEffects = {}
    local postEffects = {"Bloom", "Blur", "ColorCorrection", "SunRays", "DepthOfField", "Atmosphere"}
    for _, effect in ipairs(postEffects) do
        local e = self.Lighting:FindFirstChild(effect)
        if e then
            self.DefaultPostEffects[effect] = {
                Enabled = e.Enabled
            }
        end
    end
    
    self:LoadDefaultSettings()
    self:CreateUI(Tab)
    self:StartVisualLoop()
    
    return self
end

function Visuals:LoadDefaultSettings()
    self.DefaultVisualSettings = {
        FullBright = false,
        NoFog = false,
        NoShadows = false,
        CustomTime = false,
        CustomTimeValue = 12,
        CustomBrightness = false,
        BrightnessValue = 2,
        CustomAmbient = false,
        AmbientColor = Color3.fromRGB(255, 255, 255),
        CustomOutdoorAmbient = false,
        OutdoorAmbientColor = Color3.fromRGB(128, 128, 128),
        CustomExposure = false,
        ExposureValue = 0,
        CustomColorShift = false,
        ColorShiftTop = Color3.fromRGB(255, 255, 255),
        ColorShiftBottom = Color3.fromRGB(0, 0, 0),
        CustomEnvironmentScale = false,
        EnvironmentDiffuseScale = 1,
        EnvironmentSpecularScale = 1,
        DisableBloom = false,
        DisableBlur = false,
        DisableColorCorrection = false,
        DisableSunRays = false,
        DisableDepthOfField = false,
        DisableAtmosphere = false,
        CustomFog = false,
        FogColor = Color3.fromRGB(192, 192, 192),
        FogStart = 0,
        FogEnd = 100000,
        CustomShadows = false,
        ShadowSoftness = 0.2,
        SkyboxEnabled = false,
        SkyboxId = "",
        ThirdPerson = false,
        ThirdPersonDistance = 10,
        ForceMaterial = false,
        MaterialType = "SmoothPlastic",
        FPSUnlocker = false,
        FPSLimit = 240
    }
    
    -- Копируем в текущие настройки
    for k, v in pairs(self.DefaultVisualSettings) do
        self.VisualsEnv.Settings[k] = v
    end
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
        self.Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        self.Lighting.EnvironmentDiffuseScale = 1
        self.Lighting.EnvironmentSpecularScale = 1
    else
        if not settings.CustomBrightness then
            self.Lighting.Brightness = self.DefaultSettings.Brightness
        end
        if not settings.CustomTime then
            self.Lighting.ClockTime = self.DefaultSettings.ClockTime
        end
        if not settings.CustomAmbient then
            self.Lighting.Ambient = self.DefaultSettings.Ambient
        end
        if not settings.CustomOutdoorAmbient then
            self.Lighting.OutdoorAmbient = self.DefaultSettings.OutdoorAmbient
        end
        if not settings.NoFog and not settings.CustomFog then
            self.Lighting.FogEnd = self.DefaultSettings.FogEnd
            self.Lighting.FogStart = self.DefaultSettings.FogStart
        end
        if not settings.NoShadows and not settings.CustomShadows then
            self.Lighting.GlobalShadows = self.DefaultSettings.GlobalShadows
        end
        if not settings.CustomEnvironmentScale then
            self.Lighting.EnvironmentDiffuseScale = self.DefaultSettings.EnvironmentDiffuseScale
            self.Lighting.EnvironmentSpecularScale = self.DefaultSettings.EnvironmentSpecularScale
        end
    end
    
    -- NoFog
    if settings.NoFog then
        self.Lighting.FogEnd = 100000
        self.Lighting.FogStart = 100000
    elseif settings.CustomFog then
        self.Lighting.FogColor = settings.FogColor
        self.Lighting.FogStart = settings.FogStart
        self.Lighting.FogEnd = settings.FogEnd
    end
    
    -- NoShadows
    if settings.NoShadows then
        self.Lighting.GlobalShadows = false
    elseif settings.CustomShadows then
        self.Lighting.GlobalShadows = true
        self.Lighting.ShadowSoftness = settings.ShadowSoftness
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
        self.Lighting.Ambient = settings.AmbientColor
    end
    
    -- CustomOutdoorAmbient
    if settings.CustomOutdoorAmbient then
        self.Lighting.OutdoorAmbient = settings.OutdoorAmbientColor
    end
    
    -- CustomExposure
    if settings.CustomExposure then
        self.Lighting.ExposureCompensation = settings.ExposureValue
    end
    
    -- CustomColorShift
    if settings.CustomColorShift then
        self.Lighting.ColorShift_Top = settings.ColorShiftTop
        self.Lighting.ColorShift_Bottom = settings.ColorShiftBottom
    end
    
    -- CustomEnvironmentScale
    if settings.CustomEnvironmentScale then
        self.Lighting.EnvironmentDiffuseScale = settings.EnvironmentDiffuseScale
        self.Lighting.EnvironmentSpecularScale = settings.EnvironmentSpecularScale
    end
    
    -- Пост-обработка
    self:TogglePostEffect("Bloom", not settings.DisableBloom)
    self:TogglePostEffect("Blur", not settings.DisableBlur)
    self:TogglePostEffect("ColorCorrection", not settings.DisableColorCorrection)
    self:TogglePostEffect("SunRays", not settings.DisableSunRays)
    self:TogglePostEffect("DepthOfField", not settings.DisableDepthOfField)
    
    -- Atmosphere
    local atmosphere = self.Lighting:FindFirstChild("Atmosphere")
    if atmosphere then
        atmosphere.Enabled = not settings.DisableAtmosphere
    end
    
    -- Skybox
    if settings.SkyboxEnabled and settings.SkyboxId ~= "" then
        self:ApplySkybox(settings.SkyboxId)
    else
        self:RemoveSkybox()
    end
    
    -- ThirdPerson
    if settings.ThirdPerson then
        self.LocalPlayer.CameraMinZoomDistance = 0.5
        self.LocalPlayer.CameraMaxZoomDistance = settings.ThirdPersonDistance
    else
        self.LocalPlayer.CameraMinZoomDistance = 0.5
        self.LocalPlayer.CameraMaxZoomDistance = 10
    end
    
    -- ForceMaterial
    if settings.ForceMaterial then
        local material = Enum.Material[settings.MaterialType]
        if material then
            for _, part in ipairs(workspace:GetDescendants()) do
                if part:IsA("BasePart") and not part:IsDescendantOf(self.LocalPlayer.Character or workspace) then
                    part.Material = material
                end
            end
        end
    end
    
    -- FPS Unlocker
    if settings.FPSUnlocker then
        setfpscap(settings.FPSLimit)
    else
        setfpscap(60)
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
    -- Восстанавливаем Lighting
    self.Lighting.Brightness = self.DefaultSettings.Brightness
    self.Lighting.FogEnd = self.DefaultSettings.FogEnd
    self.Lighting.FogStart = self.DefaultSettings.FogStart
    self.Lighting.GlobalShadows = self.DefaultSettings.GlobalShadows
    self.Lighting.OutdoorAmbient = self.DefaultSettings.OutdoorAmbient
    self.Lighting.ClockTime = self.DefaultSettings.ClockTime
    self.Lighting.ExposureCompensation = self.DefaultSettings.ExposureCompensation
    self.Lighting.Ambient = self.DefaultSettings.Ambient
    self.Lighting.ColorShift_Top = self.DefaultSettings.ColorShift_Top
    self.Lighting.ColorShift_Bottom = self.DefaultSettings.ColorShift_Bottom
    self.Lighting.EnvironmentDiffuseScale = self.DefaultSettings.EnvironmentDiffuseScale
    self.Lighting.EnvironmentSpecularScale = self.DefaultSettings.EnvironmentSpecularScale
    self.Lighting.ShadowSoftness = self.DefaultSettings.ShadowSoftness
    
    -- Восстанавливаем пост-эффекты
    for effectName, data in pairs(self.DefaultPostEffects) do
        local effect = self.Lighting:FindFirstChild(effectName)
        if effect then
            effect.Enabled = data.Enabled
        end
    end
    
    self:RemoveSkybox()
    setfpscap(60)
    
    self.LocalPlayer.CameraMinZoomDistance = 0.5
    self.LocalPlayer.CameraMaxZoomDistance = 10
    
    -- Сбрасываем настройки на дефолтные
    for k, v in pairs(self.DefaultVisualSettings) do
        self.VisualsEnv.Settings[k] = v
    end
    
    -- Обновляем все UI элементы
    for name, element in pairs(self.UIElements) do
        if element and element.SetValue then
            local defaultValue = self.DefaultVisualSettings[name]
            if defaultValue ~= nil then
                pcall(function()
                    element:SetValue(defaultValue)
                end)
            end
        end
    end
    
    print("All visuals restored to defaults!")
end

function Visuals:StartVisualLoop()
    self.Connections.RenderStepped = self.RunService.RenderStepped:Connect(function()
        self:ApplySettings()
    end)
end

function Visuals:CreateUI(Tab)
    local Lighting = Tab:AddLeftGroupbox("Lighting")
    local PostProcessing = Tab:AddRightGroupbox("Post Processing")
    local Environment = Tab:AddLeftGroupbox("Environment")
    local Misc = Tab:AddRightGroupbox("Misc")
    
    -- Lighting Group
    self.UIElements["FullBright"] = Lighting:AddToggle("FullBright", {
        Text = "Full Bright",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.FullBright = v end
    })
    
    self.UIElements["NoFog"] = Lighting:AddToggle("NoFog", {
        Text = "No Fog",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.NoFog = v end
    })
    
    self.UIElements["NoShadows"] = Lighting:AddToggle("NoShadows", {
        Text = "No Shadows",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.NoShadows = v end
    })
    
    self.UIElements["CustomTime"] = Lighting:AddToggle("CustomTime", {
        Text = "Custom Time",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.CustomTime = v end
    })
    
    self.UIElements["CustomTimeValue"] = Lighting:AddSlider("CustomTimeValue", {
        Text = "Time (0-24)",
        Default = 12,
        Min = 0,
        Max = 24,
        Rounding = 1,
        Callback = function(v) self.VisualsEnv.Settings.CustomTimeValue = v end
    })
    
    self.UIElements["CustomBrightness"] = Lighting:AddToggle("CustomBrightness", {
        Text = "Custom Brightness",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.CustomBrightness = v end
    })
    
    self.UIElements["BrightnessValue"] = Lighting:AddSlider("BrightnessValue", {
        Text = "Brightness",
        Default = 2,
        Min = 0,
        Max = 10,
        Rounding = 1,
        Callback = function(v) self.VisualsEnv.Settings.BrightnessValue = v end
    })
    
    self.UIElements["CustomAmbient"] = Lighting:AddToggle("CustomAmbient", {
        Text = "Custom Ambient",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.CustomAmbient = v end
    })
    
    self.UIElements["AmbientColor"] = Lighting:AddLabel("Ambient Color"):AddColorPicker("AmbientColor", {
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(v) self.VisualsEnv.Settings.AmbientColor = v end
    })
    
    self.UIElements["CustomOutdoorAmbient"] = Lighting:AddToggle("CustomOutdoorAmbient", {
        Text = "Custom Outdoor Ambient",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.CustomOutdoorAmbient = v end
    })
    
    self.UIElements["OutdoorAmbientColor"] = Lighting:AddLabel("Outdoor Ambient"):AddColorPicker("OutdoorAmbientColor", {
        Default = Color3.fromRGB(128, 128, 128),
        Callback = function(v) self.VisualsEnv.Settings.OutdoorAmbientColor = v end
    })
    
    self.UIElements["CustomExposure"] = Lighting:AddToggle("CustomExposure", {
        Text = "Custom Exposure",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.CustomExposure = v end
    })
    
    self.UIElements["ExposureValue"] = Lighting:AddSlider("ExposureValue", {
        Text = "Exposure",
        Default = 0,
        Min = -5,
        Max = 5,
        Rounding = 1,
        Callback = function(v) self.VisualsEnv.Settings.ExposureValue = v end
    })
    
    self.UIElements["CustomColorShift"] = Lighting:AddToggle("CustomColorShift", {
        Text = "Custom Color Shift",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.CustomColorShift = v end
    })
    
    self.UIElements["ColorShiftTop"] = Lighting:AddLabel("Color Top"):AddColorPicker("ColorShiftTop", {
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(v) self.VisualsEnv.Settings.ColorShiftTop = v end
    })
    
    self.UIElements["ColorShiftBottom"] = Lighting:AddLabel("Color Bottom"):AddColorPicker("ColorShiftBottom", {
        Default = Color3.fromRGB(0, 0, 0),
        Callback = function(v) self.VisualsEnv.Settings.ColorShiftBottom = v end
    })
    
    -- Environment Group
    self.UIElements["CustomFog"] = Environment:AddToggle("CustomFog", {
        Text = "Custom Fog",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.CustomFog = v end
    })
    
    self.UIElements["FogColor"] = Environment:AddLabel("Fog Color"):AddColorPicker("FogColor", {
        Default = Color3.fromRGB(192, 192, 192),
        Callback = function(v) self.VisualsEnv.Settings.FogColor = v end
    })
    
    self.UIElements["FogStart"] = Environment:AddSlider("FogStart", {
        Text = "Fog Start",
        Default = 0,
        Min = 0,
        Max = 100000,
        Rounding = 0,
        Callback = function(v) self.VisualsEnv.Settings.FogStart = v end
    })
    
    self.UIElements["FogEnd"] = Environment:AddSlider("FogEnd", {
        Text = "Fog End",
        Default = 100000,
        Min = 0,
        Max = 100000,
        Rounding = 0,
        Callback = function(v) self.VisualsEnv.Settings.FogEnd = v end
    })
    
    self.UIElements["CustomShadows"] = Environment:AddToggle("CustomShadows", {
        Text = "Custom Shadows",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.CustomShadows = v end
    })
    
    self.UIElements["ShadowSoftness"] = Environment:AddSlider("ShadowSoftness", {
        Text = "Shadow Softness",
        Default = 0.2,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) self.VisualsEnv.Settings.ShadowSoftness = v end
    })
    
    self.UIElements["CustomEnvironmentScale"] = Environment:AddToggle("CustomEnvironmentScale", {
        Text = "Custom Environment Scale",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.CustomEnvironmentScale = v end
    })
    
    self.UIElements["EnvironmentDiffuseScale"] = Environment:AddSlider("EnvironmentDiffuseScale", {
        Text = "Diffuse Scale",
        Default = 1,
        Min = 0,
        Max = 5,
        Rounding = 2,
        Callback = function(v) self.VisualsEnv.Settings.EnvironmentDiffuseScale = v end
    })
    
    self.UIElements["EnvironmentSpecularScale"] = Environment:AddSlider("EnvironmentSpecularScale", {
        Text = "Specular Scale",
        Default = 1,
        Min = 0,
        Max = 5,
        Rounding = 2,
        Callback = function(v) self.VisualsEnv.Settings.EnvironmentSpecularScale = v end
    })
    
    self.UIElements["SkyboxEnabled"] = Environment:AddToggle("SkyboxEnabled", {
        Text = "Custom Skybox",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.SkyboxEnabled = v end
    })
    
    self.UIElements["SkyboxId"] = Environment:AddDropdown("SkyboxId", {
        Values = {
            "rbxassetid://123456789",
            "rbxassetid://987654321",
            "rbxassetid://111111111"
        },
        Default = "",
        Text = "Skybox ID",
        Callback = function(v) self.VisualsEnv.Settings.SkyboxId = v end
    })
    
    -- Post Processing Group
    self.UIElements["DisableBloom"] = PostProcessing:AddToggle("DisableBloom", {
        Text = "Disable Bloom",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.DisableBloom = v end
    })
    
    self.UIElements["DisableBlur"] = PostProcessing:AddToggle("DisableBlur", {
        Text = "Disable Blur",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.DisableBlur = v end
    })
    
    self.UIElements["DisableColorCorrection"] = PostProcessing:AddToggle("DisableColorCorrection", {
        Text = "Disable Color Correction",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.DisableColorCorrection = v end
    })
    
    self.UIElements["DisableSunRays"] = PostProcessing:AddToggle("DisableSunRays", {
        Text = "Disable Sun Rays",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.DisableSunRays = v end
    })
    
    self.UIElements["DisableDepthOfField"] = PostProcessing:AddToggle("DisableDepthOfField", {
        Text = "Disable Depth of Field",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.DisableDepthOfField = v end
    })
    
    self.UIElements["DisableAtmosphere"] = PostProcessing:AddToggle("DisableAtmosphere", {
        Text = "Disable Atmosphere",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.DisableAtmosphere = v end
    })
    
    -- Misc Group
    self.UIElements["ThirdPerson"] = Misc:AddToggle("ThirdPerson", {
        Text = "Third Person",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.ThirdPerson = v end
    })
    
    self.UIElements["ThirdPersonDistance"] = Misc:AddSlider("ThirdPersonDistance", {
        Text = "Distance",
        Default = 10,
        Min = 1,
        Max = 30,
        Rounding = 1,
        Callback = function(v) self.VisualsEnv.Settings.ThirdPersonDistance = v end
    })
    
    self.UIElements["ForceMaterial"] = Misc:AddToggle("ForceMaterial", {
        Text = "Force Material",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.ForceMaterial = v end
    })
    
    self.UIElements["MaterialType"] = Misc:AddDropdown("MaterialType", {
        Values = {"SmoothPlastic", "Metal", "Glass", "Neon", "Wood", "Brick", "Concrete", "DiamondPlate"},
        Default = "SmoothPlastic",
        Text = "Material Type",
        Callback = function(v) self.VisualsEnv.Settings.MaterialType = v end
    })
    
    self.UIElements["FPSUnlocker"] = Misc:AddToggle("FPSUnlocker", {
        Text = "FPS Unlocker",
        Default = false,
        Callback = function(v) self.VisualsEnv.Settings.FPSUnlocker = v end
    })
    
    self.UIElements["FPSLimit"] = Misc:AddSlider("FPSLimit", {
        Text = "FPS Limit",
        Default = 240,
        Min = 60,
        Max = 1000,
        Rounding = 0,
        Callback = function(v) self.VisualsEnv.Settings.FPSLimit = v end
    })
    
    -- Restore Button
    Misc:AddDivider()
    Misc:AddButton("Restore Defaults", function()
        self:RestoreDefaults()
    end)
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
