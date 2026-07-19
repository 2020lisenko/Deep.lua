local originalRepo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local myRepo       = "https://raw.githubusercontent.com/2020lisenko/Deep.lua/main/"

local Library      = loadstring(game:HttpGet(originalRepo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(originalRepo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(originalRepo .. "addons/SaveManager.lua"))()

local Options = Library.Options

Library.ForceCheckbox             = false
Library.ShowToggleFrameInKeybinds = true

local MODULE_NAMES = {"aimbot", "hitbox", "esp", "visuals", "player"}

local ModuleLoader = {
    Repo          = myRepo,
    LoadedModules = {},
}

function ModuleLoader:TryLoadString(src, moduleName)
    local fn, err = loadstring(src)
    if not fn then
        warn("[Deep.lua] Syntax error in " .. moduleName .. ":", err)
        return nil
    end
    local ok, result = pcall(fn)
    if not ok then
        warn("[Deep.lua] Runtime error in " .. moduleName .. ":", result)
        return nil
    end
    return result
end

function ModuleLoader:TryHttpGet(moduleName)
    local url = self.Repo .. moduleName .. ".lua"
    local success, data = pcall(function()
        return game:HttpGet(url)
    end)
    if success and data then
        return self:TryLoadString(data, moduleName)
    end
    return nil
end

function ModuleLoader:TryEmbedded(moduleName)
    local embedded = _G["_DeepModule_" .. moduleName]
    if embedded then
        return self:TryLoadString(embedded, moduleName)
    end
    return nil
end

function ModuleLoader:Load(moduleName, ...)
    local module = self:TryHttpGet(moduleName)
    if not module then
        module = self:TryEmbedded(moduleName)
    end

    if module then
        local ok, instance = pcall(module.Initialize, module, ...)
        if ok and instance then
            self.LoadedModules[moduleName] = instance
            return instance
        else
            warn("[Deep.lua] Initialize failed in " .. moduleName .. ":", instance)
        end
    end

    warn("[Deep.lua] Failed to load " .. moduleName)
    Library:Notify({
        Title       = "Deep.lua — Load Error",
        Description = moduleName .. " failed to load from GitHub.\nCheck your internet connection.",
        Time        = 6,
        Icon        = "triangle-alert",
    })
    return nil
end

function ModuleLoader:CleanupAll()
    for _, module in pairs(self.LoadedModules) do
        if module and module.Cleanup then
            pcall(module.Cleanup, module)
        end
    end
    self.LoadedModules = {}
end

local Window = Library:CreateWindow({
    Title                = "Deep.lua",
    Footer               = "v1.67  ·  by Zeptome",
    Icon                 = 11717093063,
    NotifySide           = "Right",
    ShowCustomCursor     = true,
    Resizable            = true,
    EnableSidebarResize  = true,
    CornerRadius         = 8,
    Animations           = true,
})

local Tabs = {
    Combat     = Window:AddTab("Combat",     "swords"),
    ESP        = Window:AddTab("ESP",        "eye"),
    Visuals    = Window:AddTab("Visuals",    "palette"),
    Player     = Window:AddTab("Player",     "user"),
    UISettings = Window:AddTab("UI",         "settings"),
}

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})
ThemeManager:SetFolder("Deep.lua")
SaveManager:SetFolder("Deep.lua/specific-game")
SaveManager:SetSubFolder("specific-place")

local Watermark = Library:AddDraggableLabel(
    "Deep.lua  |  — fps  |  — ms",
    11717093063,
    "Left"
)
Watermark:SetVisible(true)

local FrameTimer   = tick()
local FrameCounter = 0
local FPS          = 60

local WatermarkConnection = game:GetService("RunService").RenderStepped:Connect(function()
    FrameCounter += 1
    if (tick() - FrameTimer) >= 1 then
        FPS        = FrameCounter
        FrameTimer = tick()
        FrameCounter = 0
    end

    local ping = math.floor(
        game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
    )
    Watermark:SetText(("Deep.lua  |  %d fps  |  %d ms"):format(math.floor(FPS), ping))
end)

local AimbotModule  = ModuleLoader:Load("aimbot",  Tabs.Combat)
local HitboxModule  = ModuleLoader:Load("hitbox",  Tabs.Combat)
local ESPModule     = ModuleLoader:Load("esp",     Tabs.ESP)
local VisualsModule = ModuleLoader:Load("visuals", Tabs.Visuals)
local PlayerModule  = ModuleLoader:Load("player",  Tabs.Player)

local MenuGroup = Tabs.UISettings:AddRightGroupbox("Menu", "wrench")

local UIGroup = Tabs.UISettings:AddLeftGroupbox("Interface", "monitor")

UIGroup:AddToggle("ShowCustomCursor", {
    Text    = "Custom Cursor",
    Default = Library.ShowCustomCursor,
    Tooltip = "Shows a custom cursor while the menu is open.",
    Callback = function(v)
        Library.ShowCustomCursor = v
    end,
})

UIGroup:AddToggle("ShowWatermark", {
    Text    = "Show Watermark",
    Default = true,
    Tooltip = "Toggles the FPS / ping label in the top-left corner.",
    Callback = function(v)
        Watermark:SetVisible(v)
    end,
})

UIGroup:AddDivider()

UIGroup:AddDropdown("NotificationSide", {
    Values  = {"Left", "Right"},
    Default = "Right",
    Text    = "Notification Side",
    Tooltip = "Which side of the screen notifications pop up on.",
    Callback = function(v)
        Library:SetNotifySide(v)
    end,
})

UIGroup:AddDropdown("DPIDropdown", {
    Values  = {"50%", "75%", "100%", "125%", "150%", "175%", "200%"},
    Default = "100%",
    Text    = "DPI Scale",
    Tooltip = "Scales the entire UI. Useful on high-resolution monitors.",
    Callback = function(v)
        local dpi = tonumber(tostring(v):gsub("%%", ""))
        Library:SetDPIScale(dpi)
    end,
})

UIGroup:AddSlider("UICornerSlider", {
    Text     = "Corner Radius",
    Default  = 8,
    Min      = 0,
    Max      = 20,
    Rounding = 0,
    Tooltip  = "Controls how rounded the UI corners are (0 = sharp, 20 = pill).",
    Callback = function(v)
        Window:SetCornerRadius(v)
    end,
})

ThemeManager:ApplyToTab(Tabs.UISettings)
SaveManager:BuildConfigSection(Tabs.UISettings)

MenuGroup:AddToggle("KeybindMenuOpen", {
    Text    = "Open Keybind Menu",
    Default = Library.KeybindFrame.Visible,
    Tooltip = "Shows or hides the floating keybind list.",
    Callback = function(v)
        Library.KeybindFrame.Visible = v
    end,
})

MenuGroup:AddDivider()

MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
    Default = "RightShift",
    Text    = "Menu keybind",
})

MenuGroup:AddDivider()

MenuGroup:AddButton({
    Text = "Unload Deep.lua",
    Func = function()
        local Dialog = Window:AddDialog("UnloadConfirm", {
            Title = "Unload Deep.lua?",
            Icon  = "triangle-alert",
            FooterButtons = {
                {
                    Text = "Unload",
                    Callback = function()
                        Library:Unload()
                    end,
                },
                {
                    Text = "Cancel",
                    Callback = function() end,
                },
            },
        })

        Dialog:AddLabel("All active features will be disabled and\nthe UI will be removed from the game.")
    end,
    Tooltip = "Completely removes Deep.lua from the game.",
})

local PanicButton = Library:AddDraggableButton(
    "⬛ Panic",
    "x",
    "Right",
    function()
        Library:Unload()
    end
)

Library.ToggleKeybind = Options.MenuKeybind

ThemeManager:ApplyTheme("Material")
SaveManager:LoadAutoloadConfig()

task.delay(0.5, function()
    local place = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    Library:Notify({
        Title       = "Deep.lua",
        Description = ("Loaded in %s\nPress %s to toggle the menu."):format(
            place,
            "RightShift"
        ),
        Time        = 7,
        BigIcon     = tostring(11717093063),
        Icon        = "zap",
    })
end)

Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    Watermark:Destroy()
    pcall(function() PanicButton:Destroy() end)
    ModuleLoader:CleanupAll()
    getgenv().Deep        = nil
    getgenv().DeepESP     = nil
    getgenv().DeepVisuals = nil
    getgenv().DeepPlayer  = nil
end)
