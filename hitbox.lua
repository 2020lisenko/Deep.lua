local Hitbox = {}
Hitbox.__index = Hitbox

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

function Hitbox:Initialize(Tab)
    local self = setmetatable({}, Hitbox)
    print("Hitbox module loading...")
    
    self.Enabled = false
    self.Size = 1
    self.Connections = {}
    self.OriginalSizes = {}
    
    local HitboxGroup = Tab:AddRightGroupbox("Hitbox Expander", "box")
    
    HitboxGroup:AddToggle("HitboxEnabled", {
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
    
    HitboxGroup:AddSlider("HitboxSize", {
        Text = "Hitbox Size",
        Default = 1,
        Min = 1,
        Max = 10,
        Rounding = 1,
        Callback = function(v)
            self.Size = v
        end
    })
    
    print("Hitbox module loaded!")
    return self
end

function Hitbox:Start()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not self.Enabled then return end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer and player.Character then
                for _, part in pairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        -- Сохраняем оригинальный размер
                        if not self.OriginalSizes[part] then
                            self.OriginalSizes[part] = part.Size
                        end
                        
                        -- Увеличиваем размер в зависимости от части тела
                        local newSize = part.Size
                        if part.Name == "Head" then
                            newSize = Vector3.new(self.Size * 2, self.Size * 1.5, self.Size * 1.5)
                        elseif part.Name:find("Torso") then
                            newSize = Vector3.new(self.Size * 2, self.Size * 2, self.Size * 1.5)
                        elseif part.Name:find("Arm") or part.Name:find("Leg") then
                            newSize = Vector3.new(self.Size, self.Size * 2, self.Size)
                        end
                        
                        part.Size = newSize
                        part.Transparency = 0.7
                    end
                end
            end
        end
    end)
    
    table.insert(self.Connections, conn)
    print("Hitbox Expander enabled")
end

function Hitbox:Stop()
    -- Восстанавливаем оригинальные размеры
    for _, player in pairs(Players:GetPlayers()) do
        if player.Character then
            for _, part in pairs(player.Character:GetChildren()) do
                if part:IsA("BasePart") then
                    if self.OriginalSizes[part] then
                        part.Size = self.OriginalSizes[part]
                    end
                    part.Transparency = 0
                end
            end
        end
    end
    self.OriginalSizes = {}
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
