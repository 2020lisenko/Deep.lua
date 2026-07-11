-- Используем оригинальный репозиторий для библиотек
local originalRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local myRepo = "https://raw.githubusercontent.com/2020lisenko/Deep.lua/refs/heads/main/"

-- Загружаем библиотеки из оригинального репозитория (где они есть)
local Library = loadstring(game:HttpGet(originalRepo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(originalRepo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(originalRepo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

-- Встроенный ModuleLoader (не загружаем отдельно)
local ModuleLoader = {
    Repo = myRepo,
    LoadedModules = {}
}

function ModuleLoader:LoadModule(moduleName, ...)
    local url = self.Repo .. moduleName .. ".lua"
    print("Loading module: " .. url)
    
    local success, result = pcall(function()
        local moduleCode = game:HttpGet(url)
        local moduleFunc, err = loadstring(moduleCode)
        if not moduleFunc then
            error("Syntax error in " .. moduleName .. ": " .. tostring(err))
        end
        return moduleFunc()
    end)
    
    if success and result then
        self.LoadedModules[moduleName] = result:Initialize(...)
        return self.LoadedModules[moduleName]
    else
        warn("Failed to load " .. moduleName .. ":", result)
    end
    return nil
end

function ModuleLoader:CleanupAll()
    for name, module in pairs(self.LoadedModules) do
        if module and module.Cleanup then
            pcall(module.Cleanup, module)
        end
    end
    self.LoadedModules = {}
end

-- Создание окна
local Window = Library:CreateWindow({
    Title = "Deep.lua",
    Footer = "version: 1.0 | by deivid",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

-- Создание вкладок
local Tabs = {
    Aimbot = Window:AddTab("Aimbot", "crosshair"),
    ESP = Window:AddTab("ESP", "eye"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- Настройка ThemeManager и SaveManager
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("Deep.lua")
SaveManager:SetFolder("Deep.lua/specific-game")
SaveManager:SetSubFolder("specific-place")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

-- Загружаем модули из ВАШЕГО репозитория
local AimbotModule = ModuleLoader:LoadModule("aimbot", Tabs.Aimbot)
local ESPModule = ModuleLoader:LoadModule("esp", Tabs.ESP)

-- UI Settings
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end,
})

MenuGroup:AddToggle("ShowCustomCursor", {
    Text = "Custom Cursor",
    Default = Library.ShowCustomCursor,
    Callback = function(Value)
        Library.ShowCustomCursor = Value
    end,
})

MenuGroup:AddDropdown("NotificationSide", {
    Values = {"Left", "Right"},
    Default = "Right",
    Text = "Notification Side",
    Callback = function(Value)
        Library:SetNotifySide(Value)
    end,
})

MenuGroup:AddDropdown("DPIDropdown", {
    Values = {"50%", "75%", "100%", "125%", "150%", "175%", "200%"},
    Default = "100%",
    Text = "DPI Scale",
    Callback = function(Value)
        Value = Value:gsub("%%", "")
        local DPI = tonumber(Value)
        Library:SetDPIScale(DPI)
    end,
})

MenuGroup:AddSlider("UICornerSlider", {
    Text = "Corner Radius",
    Default = Library.CornerRadius,
    Min = 0,
    Max = 20,
    Rounding = 0,
    Callback = function(value)
        Window:SetCornerRadius(value)
    end
})

MenuGroup:AddDivider()
MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", { 
    Default = "RightShift", 
    NoUI = true, 
    Text = "Menu keybind" 
})

MenuGroup:AddButton("Unload", function()
    ModuleLoader:CleanupAll()
    getgenv().Deep = nil
    getgenv().DeepESP = nil
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

-- Тема
local CustomTheme = {
    Accent = Color3.fromRGB(0, 150, 255),
    AccentColor2 = Color3.fromRGB(255, 255, 255),
    Background = Color3.fromRGB(10, 10, 20),
    BackgroundColor2 = Color3.fromRGB(20, 20, 35),
    CustomFont = "Gotham",
    ElementBorder = Color3.fromRGB(0, 150, 255),
    FontColor = Color3.fromRGB(255, 255, 255),
    FontColorSecondary = Color3.fromRGB(150, 150, 200),
    NavBarColor = Color3.fromRGB(5, 5, 15),
    NavBarAccentColor = Color3.fromRGB(0, 150, 255),
    Red = Color3.fromRGB(255, 50, 50),
    RiskyColor = Color3.fromRGB(255, 50, 50),
    TabColor = Color3.fromRGB(15, 15, 25),
    TabTextColor = Color3.fromRGB(200, 200, 255),
    TabTextColorSelected = Color3.fromRGB(0, 150, 255),
}

for k, v in next, CustomTheme do
    Library.Scheme[k] = v
end

Library:UpdateColorsUsingScheme()
SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
    print("Deep.lua unloaded!")
    ModuleLoader:CleanupAll()
    getgenv().Deep = nil
    getgenv().DeepESP = nil
end)
