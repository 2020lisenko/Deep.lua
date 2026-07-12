local Hitbox = {}
Hitbox.__index = Hitbox

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

function Hitbox:Initialize(Tab)
    local self = setmetatable({}, Hitbox)
    print("Hitbox module loading...")
    
    self.Enabled = false
    self.Size = 50
    self.Transparency = 0.7
    self.Connections = {}
    
    local HitboxGroup = Tab:AddRightGroupbox("Hitbox Expander", "box")
    
    local HitboxToggle = HitboxGroup:AddToggle("HitboxEnabled", {
        Text = "Enable Hitbox Expander",
        Default = false,
        Callback = function(v)
            self.Enabled = v
            if v then
                self:Start()
            else
                self:Stop()
            end
        end
    })
    
    HitboxToggle:AddKeyPicker("HitboxKeybind", {
        Text = "Hitbox Keybind",
        Default = "H",
        Mode = "Toggle",
        SyncToggleState = true,
        Callback = function(v)
            self.Enabled = v
            if v then
                self:Start()
            else
                self:Stop()
            end
        end
    })
    
    HitboxGroup:AddSlider("HitboxSize", {
        Text = "Hitbox Size",
        Default = 50,
        Min = 1,
        Max = 500,
        Rounding = 0,
        Callback = function(v)
            self.Size = v
        end
    })
    
    HitboxGroup:AddSlider("HitboxTransparency", {
        Text = "Transparency",
        Default = 0.7,
        Min = 0,
        Max = 1,
        Rounding = 1,
        Callback = function(v)
            self.Transparency = v
        end
    })
    
    HitboxGroup:AddToggle("HitboxColorEnabled", {
        Text = "Enable Color",
        Default = true,
        Callback = function(v)
            self.ColorEnabled = v
        end
    })
    
    HitboxGroup:AddLabel("Hitbox Color"):AddColorPicker("HitboxColor", {
        Default = Color3.fromRGB(0, 105, 255),
        Callback = function(v)
            self.Color = v
        end
    })
    
    HitboxGroup:AddToggle("HitboxMaterialEnabled", {
        Text = "Enable Neon Material",
        Default = true,
        Callback = function(v)
            self.MaterialEnabled = v
        end
    })
    
    HitboxGroup:AddToggle("HitboxCanCollide", {
        Text = "Can Collide",
        Default = false,
        Callback = function(v)
            self.CanCollide = v
        end
    })
    
    self.ColorEnabled = true
    self.Color = Color3.fromRGB(0, 105, 255)
    self.MaterialEnabled = true
    self.CanCollide = false
    
    print("Hitbox module loaded!")
    return self
end

function Hitbox:Start()
    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not self.Enabled then return end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer and player.Character then
                pcall(function()
                    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                    if rootPart then
                        rootPart.Size = Vector3.new(self.Size, self.Size, self.Size)
                        rootPart.Transparency = self.Transparency
                        rootPart.CanCollide = self.CanCollide
                        
                        if self.ColorEnabled then
                            rootPart.BrickColor = BrickColor.new(self.Color)
                        end
                        
                        if self.MaterialEnabled then
                            rootPart.Material = "Neon"
                        end
                    end
                end)
            end
        end
    end)
    
    table.insert(self.Connections, conn)
    print("Hitbox Expander enabled")
end

function Hitbox:Stop()
    -- Восстанавливаем оригинальные параметры
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer and player.Character then
            pcall(function()
                local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.Size = Vector3.new(2, 2, 1) -- Стандартный размер
                    rootPart.Transparency = 0
                    rootPart.CanCollide = true
                    rootPart.Material = "Plastic"
                end
            end)
        end
    end
    print("Hitbox Expander disabled")
end

function Hitbox:Cleanup()
    self.Enabled = false
    self:Stop()
    
    for _, conn in pairs(self.Connections) do
        if conn then
            conn:Disconnect()
        end
    end
    self.Connections = {}
    
    print("Hitbox cleanup!")
end

return Hitbox
