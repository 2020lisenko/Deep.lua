local Visuals = {}
Visuals.__index = Visuals

function Visuals:Initialize(Tab)
    local self = setmetatable({}, Visuals)
    
    if not getgenv().DeepVisuals then
        getgenv().DeepVisuals = {}
    end
    
    self.VisualsEnv = getgenv().DeepVisuals
    
    self.Lighting = game:GetService("Lighting")
    self.Players = game:GetService("Players")
    self.LocalPlayer = self.Players.LocalPlayer
    
    self.OriginalValues = {
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
    
    self:LoadDefaultSettings()
    self:CreateUI(Tab)
    
    return self
end

function Visuals:LoadDefaultSettings()
    self.VisualsEnv.Settings = {
        FullBright = false,
        NoFog = false,
        NoShadows = false,
        CustomTime = false,
        CustomTimeValue = 12,
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
        CustomFog = false,
        FogColor = Color3.fromRGB(192, 192, 192),
        FogStart = 0,
        FogEnd = 100000,
        CustomShadows = false,
        ShadowSoftness = 0.2,
        SkyboxEnabled = false,
        SkyboxId = "",
        ThirdPerson = false,
        ThirdPersonDistance = 10
    }
end

function Visuals:ApplyFullBright()
    if self.VisualsEnv.Settings.FullBright then
        self.Lighting.Brightness = 2
        self.Lighting.ClockTime = 14
        self.Lighting.FogEnd = 100000
        self.Lighting.GlobalShadows = false
        self.Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        self.Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        self.Lighting.EnvironmentDiffuseScale = 1
        self.Lighting.EnvironmentSpecularScale = 1
    else
        self.Lighting.Brightness = self.OriginalValues.Brightness
        self.Lighting.ClockTime = self.OriginalValues.ClockTime
        self.Lighting.FogEnd = self.OriginalValues.FogEnd
        self.Lighting.GlobalShadows = self.OriginalValues.GlobalShadows
        self.Lighting.OutdoorAmbient = self.OriginalValues.OutdoorAmbient
        self.Lighting.Ambient = self.OriginalValues.Ambient
        self.Lighting.EnvironmentDiffuseScale = self.OriginalValues.EnvironmentDiffuseScale
        self.Lighting.EnvironmentSpecularScale = self.OriginalValues.EnvironmentSpecularScale
        
        self:ApplyCustomTime()
        self:ApplyCustomAmbient()
        self:ApplyCustomOutdoorAmbient()
        self:ApplyCustomEnvironmentScale()
        self:ApplyNoFog()
        self:ApplyNoShadows()
    end
end

function Visuals:ApplyNoFog()
    if self.VisualsEnv.Settings.NoFog then
        self.Lighting.FogEnd = 100000
        self.Lighting.FogStart = 100000
    elseif self.VisualsEnv.Settings.CustomFog then
        self.Lighting.FogColor = self.VisualsEnv.Settings.FogColor
        self.Lighting.FogStart = self.VisualsEnv.Settings.FogStart
        self.Lighting.FogEnd = self.VisualsEnv.Settings.FogEnd
    else
        self.Lighting.FogEnd = self.OriginalValues.FogEnd
        self.Lighting.FogStart = self.OriginalValues.FogStart
        self.Lighting.FogColor = self.OriginalValues.FogColor or Color3.fromRGB(192, 192, 192)
    end
end

function Visuals:ApplyNoShadows()
    if self.VisualsEnv.Settings.NoShadows then
        self.Lighting.GlobalShadows = false
    elseif self.VisualsEnv.Settings.CustomShadows then
        self.Lighting.GlobalShadows = true
        self.Lighting.ShadowSoftness = self.VisualsEnv.Settings.ShadowSoftness
    else
        self.Lighting.GlobalShadows = self.OriginalValues.GlobalShadows
        self.Lighting.ShadowSoftness = self.OriginalValues.ShadowSoftness
    end
end

function Visuals:ApplyCustomTime()
    if self.VisualsEnv.Settings.CustomTime then
        self.Lighting.ClockTime = self.VisualsEnv.Settings.CustomTimeValue
    end
end

function Visuals:ApplyCustomAmbient()
    if self.VisualsEnv.Settings.CustomAmbient then
        self.Lighting.Ambient = self.VisualsEnv.Settings.AmbientColor
    end
end

function Visuals:ApplyCustomOutdoorAmbient()
    if self.VisualsEnv.Settings.CustomOutdoorAmbient then
        self.Lighting.OutdoorAmbient = self.VisualsEnv.Settings.OutdoorAmbientColor
    end
end

function Visuals:ApplyCustomExposure()
    if self.VisualsEnv.Settings.CustomExposure then
        self.Lighting.ExposureCompensation = self.VisualsEnv.Settings.ExposureValue
    end
end

function Visuals:ApplyCustomColorShift()
    if self.VisualsEnv.Settings.CustomColorShift then
        self.Lighting.ColorShift_Top = self.VisualsEnv.Settings.ColorShiftTop
        self.Lighting.ColorShift_Bottom = self.VisualsEnv.Settings.ColorShiftBottom
    end
end

function Visuals:ApplyCustomEnvironmentScale()
    if self.VisualsEnv.Settings.CustomEnvironmentScale then
        self.Lighting.EnvironmentDiffuseScale = self.VisualsEnv.Settings.EnvironmentDiffuseScale
        self.Lighting.EnvironmentSpecularScale = self.VisualsEnv.Settings.EnvironmentSpecularScale
    end
end

function Visuals:ApplySkybox()
    if self.VisualsEnv.Settings.SkyboxEnabled and self.VisualsEnv.Settings.SkyboxId ~= "" then
        self:RemoveSkybox()
        local sky = Instance.new("Sky")
        sky.Name = "DeepCustomSky"
        sky.SkyboxBk = self.VisualsEnv.Settings.SkyboxId
        sky.SkyboxDn = self.VisualsEnv.Settings.SkyboxId
        sky.SkyboxFt = self.VisualsEnv.Settings.SkyboxId
        sky.SkyboxLf = self.VisualsEnv.Settings.SkyboxId
        sky.SkyboxRt = self.VisualsEnv.Settings.SkyboxId
        sky.SkyboxUp = self.VisualsEnv.Settings.SkyboxId
        sky.Parent = self.Lighting
    else
        self:RemoveSkybox()
    end
end

function Visuals:RemoveSkybox()
    for _, child in ipairs(self.Lighting:GetChildren()) do
        if child:IsA("Sky") and child.Name == "DeepCustomSky" then
            child:Destroy()
        end
    end
end

function Visuals:ApplyThirdPerson()
    if self.VisualsEnv.Settings.ThirdPerson then
        self.LocalPlayer.CameraMinZoomDistance = 0.5
        self.LocalPlayer.CameraMaxZoomDistance = self.VisualsEnv.Settings.ThirdPersonDistance
    else
        self.LocalPlayer.CameraMinZoomDistance = 0.5
        self.LocalPlayer.CameraMaxZoomDistance = 10
    end
end

function Visuals:RestoreAll()
    for k, v in pairs(self.OriginalValues) do
        self.Lighting[k] = v
    end
    
    self:RemoveSkybox()
    
    self.LocalPlayer.CameraMinZoomDistance = 0.5
    self.LocalPlayer.CameraMaxZoomDistance = 10
    
    self:LoadDefaultSettings()
    
    print("All visuals restored to defaults!")
end

function Visuals:CreateUI(Tab)
    local Lighting = Tab:AddLeftGroupbox("Lighting")
    local Environment = Tab:AddRightGroupbox("Environment")
    local Misc = Tab:AddLeftGroupbox("Misc")
    
    -- Lighting Group
    Lighting:AddToggle("FullBright", {
        Text = "Full Bright",
        Default = false,
        Callback = function(v) 
            self.VisualsEnv.Settings.FullBright = v
            self:ApplyFullBright()
        end
    })
    
    Lighting:AddToggle("NoFog", {
        Text = "No Fog",
        Default = false,
        Callback = function(v) 
            self.VisualsEnv.Settings.NoFog = v
            self:ApplyNoFog()
        end
    })
    
    Lighting:AddToggle("NoShadows", {
        Text = "No Shadows",
        Default = false,
        Callback = function(v) 
            self.VisualsEnv.Settings.NoShadows = v
            self:ApplyNoShadows()
        end
    })
    
    Lighting:AddToggle("CustomTime", {
        Text = "Custom Time",
        Default = false,
        Callback = function(v) 
            self.VisualsEnv.Settings.CustomTime = v
            self:ApplyCustomTime()
        end
    })
    
    Lighting:AddSlider("CustomTimeValue", {
        Text = "Time (0-24)",
        Default = 12,
        Min = 0,
        Max = 24,
        Rounding = 1,
        Callback = function(v) 
            self.VisualsEnv.Settings.CustomTimeValue = v
            self:ApplyCustomTime()
        end
    })
    
    Lighting:AddToggle("CustomAmbient", {
        Text = "Custom Ambient",
        Default = false,
        Callback = function(v) 
            self.VisualsEnv.Settings.CustomAmbient = v
            self:ApplyCustomAmbient()
        end
    })
    
    Lighting:AddLabel("Ambient Color"):AddColorPicker("AmbientColor", {
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(v) 
            self.VisualsEnv.Settings.AmbientColor = v
            self:ApplyCustomAmbient()
        end
    })
    
    Lighting:AddToggle("CustomOutdoorAmbient", {
        Text = "Custom Outdoor Ambient",
        Default = false,
        Callback = function(v) 
            self.VisualsEnv.Settings.CustomOutdoorAmbient = v
            self:ApplyCustomOutdoorAmbient()
        end
    })
    
    Lighting:AddLabel("Outdoor Ambient"):AddColorPicker("OutdoorAmbientColor", {
        Default = Color3.fromRGB(128, 128, 128),
        Callback = function(v) 
            self.VisualsEnv.Settings.OutdoorAmbientColor = v
            self:ApplyCustomOutdoorAmbient()
        end
    })
    
    Lighting:AddToggle("CustomExposure", {
        Text = "Custom Exposure",
        Default = false,
        Callback = function(v) 
            self.VisualsEnv.Settings.CustomExposure = v
            self:ApplyCustomExposure()
        end
    })
    
    Lighting:AddSlider("ExposureValue", {
        Text = "Exposure",
        Default = 0,
        Min = -5,
        Max = 5,
        Rounding = 1,
        Callback = function(v) 
            self.VisualsEnv.Settings.ExposureValue = v
            self:ApplyCustomExposure()
        end
    })
    
    Lighting:AddToggle("CustomColorShift", {
        Text = "Custom Color Shift",
        Default = false,
        Callback = function(v) 
            self.VisualsEnv.Settings.CustomColorShift = v
            self:ApplyCustomColorShift()
        end
    })
    
    Lighting:AddLabel("Color Top"):AddColorPicker("ColorShiftTop", {
        Default = Color3.fromRGB(255, 255, 255),
        Callback = function(v) 
            self.VisualsEnv.Settings.ColorShiftTop = v
            self:ApplyCustomColorShift()
        end
    })
    
    Lighting:AddLabel("Color Bottom"):AddColorPicker("ColorShiftBottom", {
        Default = Color3.fromRGB(0, 0, 0),
        Callback = function(v) 
            self.VisualsEnv.Settings.ColorShiftBottom = v
            self:ApplyCustomColorShift()
        end
    })
    
    -- Environment Group
    Environment:AddToggle("CustomFog", {
        Text = "Custom Fog",
        Default = false,
        Callback = function(v) 
            self.VisualsEnv.Settings.CustomFog = v
            self:ApplyNoFog()
        end
    })
    
    Environment:AddLabel("Fog Color"):AddColorPicker("FogColor", {
        Default = Color3.fromRGB(192, 192, 192),
        Callback = function(v) 
            self.VisualsEnv.Settings.FogColor = v
            self:ApplyNoFog()
        end
    })
    
    Environment:AddSlider("FogStart", {
        Text = "Fog Start",
        Default = 0,
        Min = 0,
        Max = 100000,
        Rounding = 0,
        Callback = function(v) 
            self.VisualsEnv.Settings.FogStart = v
            self:ApplyNoFog()
        end
    })
    
    Environment:AddSlider("FogEnd", {
        Text = "Fog End",
        Default = 100000,
        Min = 0,
        Max = 100000,
        Rounding = 0,
        Callback = function(v) 
            self.VisualsEnv.Settings.FogEnd = v
            self:ApplyNoFog()
        end
    })
    
    Environment:AddToggle("CustomShadows", {
        Text = "Custom Shadows",
        Default = false,
        Callback = function(v) 
            self.VisualsEnv.Settings.CustomShadows = v
            self:ApplyNoShadows()
        end
    })
    
    Environment:AddSlider("ShadowSoftness", {
        Text = "Shadow Softness",
        Default = 0.2,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v) 
            self.VisualsEnv.Settings.ShadowSoftness = v
            self:ApplyNoShadows()
        end
    })
    
    Environment:AddToggle("CustomEnvironmentScale", {
        Text = "Custom Environment Scale",
        Default = false,
        Callback = function(v) 
            self.VisualsEnv.Settings.CustomEnvironmentScale = v
            self:ApplyCustomEnvironmentScale()
        end
    })
    
    Environment:AddSlider("EnvironmentDiffuseScale", {
        Text = "Diffuse Scale",
        Default = 1,
        Min = 0,
        Max = 5,
        Rounding = 2,
        Callback = function(v) 
            self.VisualsEnv.Settings.EnvironmentDiffuseScale = v
            self:ApplyCustomEnvironmentScale()
        end
    })
    
    Environment:AddSlider("EnvironmentSpecularScale", {
        Text = "Specular Scale",
        Default = 1,
        Min = 0,
        Max = 5,
        Rounding = 2,
        Callback = function(v) 
            self.VisualsEnv.Settings.EnvironmentSpecularScale = v
            self:ApplyCustomEnvironmentScale()
        end
    })
    
    Environment:AddToggle("SkyboxEnabled", {
        Text = "Custom Skybox",
        Default = false,
        Callback = function(v) 
            self.VisualsEnv.Settings.SkyboxEnabled = v
            self:ApplySkybox()
        end
    })
    
    Environment:AddDropdown("SkyboxId", {
        Values = {
            "rbxassetid://123456789",
            "rbxassetid://987654321",
            "rbxassetid://111111111"
        },
        Default = "",
        Text = "Skybox ID",
        Callback = function(v) 
            self.VisualsEnv.Settings.SkyboxId = v
            self:ApplySkybox()
        end
    })
    
    -- Misc Group
    Misc:AddToggle("ThirdPerson", {
        Text = "Third Person",
        Default = false,
        Callback = function(v) 
            self.VisualsEnv.Settings.ThirdPerson = v
            self:ApplyThirdPerson()
        end
    })
    
    Misc:AddSlider("ThirdPersonDistance", {
        Text = "Distance",
        Default = 10,
        Min = 1,
        Max = 100,
        Rounding = 1,
        Callback = function(v) 
            self.VisualsEnv.Settings.ThirdPersonDistance = v
            self:ApplyThirdPerson()
        end
    })
    
    Misc:AddDivider()
    Misc:AddButton("Restore Defaults", function()
        self:RestoreAll()
    end)
end

function Visuals:Cleanup()
    self:RestoreAll()
end

return Visuals
