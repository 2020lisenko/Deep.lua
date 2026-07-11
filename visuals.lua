local Visuals = {}
Visuals.__index = Visuals

function Visuals:Initialize(Tab)
    local self = setmetatable({}, Visuals)
    
    if not getgenv().DeepVisuals then
        getgenv().DeepVisuals = {}
    end
    
    self.VisualsEnv = getgenv().DeepVisuals
    self.Lighting = game:GetService("Lighting")
    self.LocalPlayer = game:GetService("Players").LocalPlayer
    
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
        ThirdPersonDistance = 10,
        FOV = false,
        FOVAmount = 1.0
    }
end

function Visuals:ApplyFullBright()
    local s = self.VisualsEnv.Settings
    if s.FullBright then
        self.Lighting.Brightness = 2
        self.Lighting.ClockTime = 14
        self.Lighting.FogEnd = 100000
        self.Lighting.GlobalShadows = false
        self.Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        self.Lighting.Ambient = Color3.fromRGB(128, 128, 128)
        self.Lighting.EnvironmentDiffuseScale = 1
        self.Lighting.EnvironmentSpecularScale = 1
    else
        for k, v in pairs(self.OriginalValues) do
            self.Lighting[k] = v
        end
        self:ApplyCustomTime()
        self:ApplyCustomAmbient()
        self:ApplyCustomOutdoorAmbient()
        self:ApplyCustomEnvironmentScale()
        self:ApplyNoFog()
        self:ApplyCustomShadows()
    end
end

function Visuals:ApplyNoFog()
    local s = self.VisualsEnv.Settings
    if s.NoFog then
        self.Lighting.FogEnd = 100000
        self.Lighting.FogStart = 100000
    elseif s.CustomFog then
        self.Lighting.FogColor = s.FogColor
        self.Lighting.FogStart = s.FogStart
        self.Lighting.FogEnd = s.FogEnd
    else
        self.Lighting.FogEnd = self.OriginalValues.FogEnd
        self.Lighting.FogStart = self.OriginalValues.FogStart
    end
end

function Visuals:ApplyCustomShadows()
    local s = self.VisualsEnv.Settings
    if s.CustomShadows then
        self.Lighting.GlobalShadows = true
        self.Lighting.ShadowSoftness = s.ShadowSoftness
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
    local s = self.VisualsEnv.Settings
    if s.SkyboxEnabled and s.SkyboxId ~= "" then
        self:RemoveSkybox()
        local sky = Instance.new("Sky")
        sky.Name = "DeepCustomSky"
        sky.SkyboxBk = s.SkyboxId
        sky.SkyboxDn = s.SkyboxId
        sky.SkyboxFt = s.SkyboxId
        sky.SkyboxLf = s.SkyboxId
        sky.SkyboxRt = s.SkyboxId
        sky.SkyboxUp = s.SkyboxId
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
    local s = self.VisualsEnv.Settings
    if s.ThirdPerson then
        self.LocalPlayer.CameraMinZoomDistance = 0.5
        self.LocalPlayer.CameraMaxZoomDistance = s.ThirdPersonDistance
    else
        self.LocalPlayer.CameraMinZoomDistance = 0.5
        self.LocalPlayer.CameraMaxZoomDistance = 10
    end
end

function Visuals:ApplyFOV()
    local cam = workspace.CurrentCamera
    if self.VisualsEnv.Settings.FOV then
        cam.FieldOfView = 70 * self.VisualsEnv.Settings.FOVAmount
    else
        cam.FieldOfView = 70
    end
end

function Visuals:RestoreAll()
    for k, v in pairs(self.OriginalValues) do
        self.Lighting[k] = v
    end
    self:RemoveSkybox()
    self.LocalPlayer.CameraMinZoomDistance = 0.5
    self.LocalPlayer.CameraMaxZoomDistance = 10
    workspace.CurrentCamera.FieldOfView = 70
    print("All visuals restored to defaults!")
end

function Visuals:CreateUI(Tab)
    local Lighting = Tab:AddLeftGroupbox("Lighting")
    local Environment = Tab:AddRightGroupbox("Environment")
    local Misc = Tab:AddLeftGroupbox("Misc")
    
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
            self:ApplyCustomShadows()
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
            self:ApplyCustomShadows()
        end
    })
    
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
    
    Misc:AddToggle("FOV", {
        Text = "FOV",
        Default = false,
        Callback = function(v)
            self.VisualsEnv.Settings.FOV = v
            self:ApplyFOV()
        end
    })
    
    Misc:AddSlider("FOVAmount", {
        Text = "FOV Scale",
        Default = 1.0,
        Min = 0.5,
        Max = 3.0,
        Rounding = 2,
        Callback = function(v)
            self.VisualsEnv.Settings.FOVAmount = v
            self:ApplyFOV()
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
