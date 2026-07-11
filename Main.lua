local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"

-- Загрузка зависимостей
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()
local ModuleLoader = loadstring(game:HttpGet(repo .. "modules/ModuleLoader.lua"))()

-- Инициализация Library
local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

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

-- Загрузка модулей
local AimbotModule = ModuleLoader:LoadModule("Aimbot", Tabs.Aimbot)
local ESPModule = ModuleLoader:LoadModule("ESP", Tabs.ESP)
local UIModule = ModuleLoader:LoadModule("UISettings", Tabs["UI Settings"], Library, Window)

-- Тема по умолчанию
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

-- Обработка выгрузки
Library:OnUnload(function()
	print("Deep.lua unloaded!")
	if ESPModule then ESPModule:Cleanup() end
	if AimbotModule then AimbotModule:Cleanup() end
	getgenv().Deep = nil
	getgenv().DeepESP = nil
end)
