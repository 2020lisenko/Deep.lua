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
    Footer = "version: 1.0 | by deivid",
    Icon = 95816097006870,
    NotifySide = "Right",
    ShowCustomCursor = true,
})

local Tabs = {
    Aimbot = Window:AddTab("Aimbot", "crosshair"),
    ESP = Window:AddTab("ESP", "eye"),
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

local AimbotModule = ModuleLoader:LoadModule("aimbot", Tabs.Aimbot)
local ESPModule = ModuleLoader:LoadModule("esp", Tabs.ESP)

local MenuGroup = Tabs["UI Settings"]:AddLeftGroupbox("Menu", "wrench")

MenuGroup:AddToggle("KeybindMenuOpen", {
    Default = Library.KeybindFrame.Visible,
    Text = "Open Keybind Menu",
    Callback = function(value)
        Library.KeybindFrame.Visible = value
    end,
})

MenuGroup:AddButton("Unload", function()
    ModuleLoader:CleanupAll()
    getgenv().Deep = nil
    getgenv().DeepESP = nil
    Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

SaveManager:LoadAutoloadConfig()

Library:OnUnload(function()
    print("Deep.lua unloaded!")
    ModuleLoader:CleanupAll()
    getgenv().Deep = nil
    getgenv().DeepESP = nil
end)
