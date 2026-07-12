local Hitbox = {}
Hitbox.__index = Hitbox

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

function Hitbox:Initialize(Tab)
    local self = setmetatable({}, Hitbox)
    print("Hitbox module loading...")
    
    self.Enabled = false
    self.Size = 1
    self.SelectedParts = {
        Head = true,
        Torso = true,
        LeftArm = false,
        RightArm = false,
        LeftLeg = false,
        RightLeg = false
    }
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
    
    HitboxGroup:AddDivider()
    HitboxGroup:AddLabel("Body Parts")
    
    HitboxGroup:AddToggle("HeadPart", {
        Text = "Head",
        Default = true,
        Callback = function(v)
            self.SelectedParts.Head = v
        end
    })
    
    HitboxGroup:AddToggle("TorsoPart", {
        Text = "Torso",
        Default = true,
        Callback = function(v)
            self.SelectedParts.Torso = v
        end
    })
    
    HitboxGroup:AddToggle("LeftArmPart", {
        Text = "Left Arm",
        Default = false,
        Callback = function(v)
            self.SelectedParts.LeftArm = v
        end
    })
    
    HitboxGroup:AddToggle("RightArmPart", {
        Text = "Right Arm",
        Default = false,
        Callback = function(v)
            self.SelectedParts.RightArm = v
        end
    })
    
    HitboxGroup:AddToggle("LeftLegPart", {
        Text = "Left Leg",
        Default = false,
        Callback = function(v)
            self.SelectedParts.LeftLeg = v
        end
    })
    
    HitboxGroup:AddToggle("RightLegPart", {
        Text = "Right Leg",
        Default = false,
        Callback = function(v)
            self.SelectedParts.RightLeg = v
        end
    })
    
    print("Hitbox module loaded!")
    return self
end

function Hitbox:ShouldModifyPart(partName)
    local name = partName:lower()
    
    if name == "head" and self.SelectedParts.Head then
        return true
    elseif (name:find("torso") or name:find("upper") or name:find("lower")) and self.SelectedParts.Torso then
        return true
    elseif (name:find("left") and name:find("arm")) and self.SelectedParts.LeftArm then
        return true
    elseif (name:find("right") and name:find("arm")) and self.SelectedParts.RightArm then
        return true
    elseif (name:find("left") and name:find("leg")) and self.SelectedParts.LeftLeg then
        return true
    elseif (name:find("right") and name:find("leg")) and self.SelectedParts.RightLeg then
        return true
    end
    
    return false
end

function Hitbox:GetNewSize(partName)
    local name = partName:lower()
    local size = self.Size
    
    if name == "head" then
        return Vector3.new(size * 2, size * 1.5, size * 1.5)
    elseif name:find("torso") or name:find("upper") or name:find("lower") then
        return Vector3.new(size * 2, size * 2, size * 1.5)
    elseif name:find("arm") then
        return Vector3.new(size, size * 2, size)
    elseif name:find("leg") then
        return Vector3.new(size, size * 2, size)
    end
    
    return nil
end

function Hitbox:Start()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        if not self.Enabled then return end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Players.LocalPlayer and player.Character then
                for _, part in pairs(player.Character:GetChildren()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        if self:ShouldModifyPart(part.Name) then
                            -- Сохраняем оригинальный размер
                            if not self.OriginalSizes[part] then
                                self.OriginalSizes[part] = part.Size
                            end
                            
                            -- Увеличиваем размер
                            local newSize = self:GetNewSize(part.Name)
                            if newSize then
                                part.Size = newSize
                                part.Transparency = 0.7
                            end
                        else
                            -- Восстанавливаем размер если часть не выбрана
                            if self.OriginalSizes[part] then
                                part.Size = self.OriginalSizes[part]
                                part.Transparency = 0
                                self.OriginalSizes[part] = nil
                            end
                        end
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
