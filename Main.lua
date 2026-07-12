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

local Window = Library:CreateWindow({
    Title = "Deep.lua",
    Footer = "version: 1.67 | by Zeptome",
    Icon = 11717093063,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Combat = Window:AddTab("Combat", "swords"),
    ESP = Window:AddTab("ESP", "eye"),
    LootESP = Window:AddTab("LootESP", "box"), -- Новая вкладка
    Visuals = Window:AddTab("Visuals", "palette"),
    Player = Window:AddTab("Player", "user"),
    ["UI Settings"] = Window:AddTab("UI Settings", "settings"),
}

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("Deep.lua")
SaveManager:SetFolder("Deep.lua/specific-game")
SaveManager:SetSubFolder("specific-place")
SaveManager:BuildConfigSection(Tabs["UI Settings"])
ThemeManager:ApplyToTab(Tabs["UI Settings"])

local Watermark = Library:AddDraggableLabel("Deep.lua | 60 fps | 0 ms", 11717093063, "Left")
Watermark:SetVisible(true)

local FrameTimer = tick()
local FrameCounter = 0
local FPS = 60

local WatermarkConnection = game:GetService("RunService").RenderStepped:Connect(function()
    FrameCounter += 1
    if (tick() - FrameTimer) >= 1 then
        FPS = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end
    
    local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
    
    Watermark:SetText(("Deep.lua | %s fps | %s ms"):format(
        math.floor(FPS),
        ping
    ))
end)

print("Loading modules...")
local AimbotModule = ModuleLoader:LoadModule("aimbot", Tabs.Combat)
local HitboxModule = ModuleLoader:LoadModule("hitbox", Tabs.Combat)
local ESPModule = ModuleLoader:LoadModule("esp", Tabs.ESP)
local LootESPModule = ModuleLoader:LoadModule("lootesp", Tabs.LootESP) -- Новый модуль
local VisualsModule = ModuleLoader:LoadModule("visuals", Tabs.Visuals)
local PlayerModule = ModuleLoader:LoadModule("player", Tabs.Player)
print("All modules loaded!")

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

MenuGroup:AddToggle("ShowWatermark", {
    Text = "Show Watermark",
    Default = true,
    Callback = function(Value)
        Watermark:SetVisible(Value)
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
    WatermarkConnection:Disconnect()
    Watermark:Destroy()
    ModuleLoader:CleanupAll()
    getgenv().Deep = nil
    getgenv().DeepESP = nil
    getgenv().DeepLootESP = nil
    getgenv().DeepVisuals = nil
    getgenv().DeepPlayer = nil
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:ApplyTheme("Material")

SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
    print("Deep.lua unloaded!")
    WatermarkConnection:Disconnect()
    Watermark:Destroy()
    ModuleLoader:CleanupAll()
    getgenv().Deep = nil
    getgenv().DeepESP = nil
    getgenv().DeepLootESP = nil
    getgenv().DeepVisuals = nil
    getgenv().DeepPlayer = nil
end)
