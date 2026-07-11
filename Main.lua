-- Main.lua
local originalRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local myRepo = "https://raw.githubusercontent.com/2020lisenko/Deep.lua/refs/heads/main/"

-- Загружаем библиотеки из оригинального репозитория
local Library = loadstring(game:HttpGet(originalRepo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(originalRepo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(originalRepo .. "addons/SaveManager.lua"))()

-- ModuleLoader для загрузки ваших модулей
local ModuleLoader = {
    Repo = myRepo,
    LoadedModules = {}
}

function ModuleLoader:LoadModule(moduleName, ...)
    local success, module = pcall(function()
        return loadstring(game:HttpGet(self.Repo .. moduleName:lower() .. ".lua"))()
    end)
    
    if success and module then
        self.LoadedModules[moduleName] = module:Initialize(...)
        return self.LoadedModules[moduleName]
    else
        warn("Failed to load module: " .. moduleName, module)
        return nil
    end
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

-- Вкладки
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

-- Загрузка модулей
local AimbotModule = ModuleLoader:LoadModule("Aimbot", Tabs.Aimbot)
local ESPModule = ModuleLoader:LoadModule("ESP", Tabs.ESP)

-- Настройки UI
local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end,
})

MenuGroup:AddButton("Unload", function()
    if ESPModule then ESPModule:Cleanup() end
    if AimbotModule then AimbotModule:Cleanup() end
    ModuleLoader:CleanupAll()
    Library:Unload()
    getgenv().Deep = nil
    getgenv().DeepESP = nil
end)

Library.ToggleKeybind = Options.MenuKeybind

-- Тема
local CustomTheme = {
    Accent = Color3.fromRGB(0, 150, 255),
    Background = Color3.fromRGB(10, 10, 20),
    -- ... остальные цвета
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
