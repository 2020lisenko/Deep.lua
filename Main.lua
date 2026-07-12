local originalRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local myRepo = "https://raw.githubusercontent.com/2020lisenko/Deep.lua/refs/heads/main/"

local Library = loadstring(game:HttpGet(originalRepo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(originalRepo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(originalRepo .. "addons/SaveManager.lua"))()

local Options = Library.Options
local Toggles = Library.Toggles

Library.ForceCheckbox = false
Library.ShowToggleFrameInKeybinds = true

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
        print("Module loaded: " .. moduleName)
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

-- Сначала создаем главное окно
local Window = Library:CreateWindow({
    Title = "Deep.lua",
    Footer = "version: 1.67 | by Zeptome",
    Icon = 11717093063,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Aimbot = Window:AddTab("Aimbot", "crosshair"),
    ESP = Window:AddTab("ESP", "eye"),
    Visuals = Window:AddTab("Visuals", "palette"),
    Player = Window:AddTab("Player", "user"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

-- Создаем окно загрузки
local Loading = Library:CreateLoading({
    Title = "Deep.lua",
    Icon = 11717093063,
    TotalSteps = 5,
    ShowSidebar = true,
})

-- Шаг 1: Инициализация
Loading:SetMessage("Initializing Deep.lua")
Loading:SetDescription("Preparing environment...")
Loading:SetCurrentStep(1)
Loading.Sidebar:AddLabel("Version: 1.67")
Loading.Sidebar:AddLabel("User: " .. game.Players.LocalPlayer.Name)
Loading.Sidebar:AddLabel("Game: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
task.wait(0.8)

-- Шаг 2: Загрузка Aimbot
Loading:SetMessage("Loading Aimbot Module")
Loading:SetDescription("Fetching aimbot.lua...")
Loading:SetCurrentStep(2)
Loading.Sidebar:AddLabel("Aimbot: Loading...")
local AimbotModule = ModuleLoader:LoadModule("aimbot", Tabs.Aimbot)
if AimbotModule then
    Loading.Sidebar:AddLabel("Aimbot: Loaded!")
else
    Loading.Sidebar:AddLabel("Aimbot: Failed!")
end
task.wait(0.5)

-- Шаг 3: Загрузка ESP
Loading:SetMessage("Loading ESP Module")
Loading:SetDescription("Fetching esp.lua...")
Loading:SetCurrentStep(3)
Loading.Sidebar:AddLabel("ESP: Loading...")
local ESPModule = ModuleLoader:LoadModule("esp", Tabs.ESP)
if ESPModule then
    Loading.Sidebar:AddLabel("ESP: Loaded!")
else
    Loading.Sidebar:AddLabel("ESP: Failed!")
end
task.wait(0.5)

-- Шаг 4: Загрузка Visuals
Loading:SetMessage("Loading Visuals Module")
Loading:SetDescription("Fetching visuals.lua...")
Loading:SetCurrentStep(4)
Loading.Sidebar:AddLabel("Visuals: Loading...")
local VisualsModule = ModuleLoader:LoadModule("visuals", Tabs.Visuals)
if VisualsModule then
    Loading.Sidebar:AddLabel("Visuals: Loaded!")
else
    Loading.Sidebar:AddLabel("Visuals: Failed!")
end
task.wait(0.5)

-- Шаг 5: Загрузка Player
Loading:SetMessage("Loading Player Module")
Loading:SetDescription("Fetching player.lua...")
Loading:SetCurrentStep(5)
Loading.Sidebar:AddLabel("Player: Loading...")
local PlayerModule = ModuleLoader:LoadModule("player", Tabs.Player)
if PlayerModule then
    Loading.Sidebar:AddLabel("Player: Loaded!")
else
    Loading.Sidebar:AddLabel("Player: Failed!")
end
task.wait(0.5)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("Deep.lua")
SaveManager:SetFolder("Deep.lua/specific-game")
SaveManager:SetSubFolder("specific-place")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

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
    Default = 16,
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
    getgenv().DeepVisuals = nil
    getgenv().DeepPlayer = nil
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

-- Применяем тему Material
ThemeManager:ApplyTheme("Material")

-- Завершаем загрузку и показываем главное окно
Loading:SetMessage("Deep.lua Loaded!")
Loading:SetDescription("Welcome, " .. game.Players.LocalPlayer.Name .. "!")
task.wait(1)
Loading:Continue()

SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
    print("Deep.lua unloaded!")
    ModuleLoader:CleanupAll()
    getgenv().Deep = nil
    getgenv().DeepESP = nil
    getgenv().DeepVisuals = nil
    getgenv().DeepPlayer = nil
end)
