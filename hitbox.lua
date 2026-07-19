local Hitbox = {}
Hitbox.__index = Hitbox

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local PART_OPTIONS = {
    "HumanoidRootPart",
    "Head",
    "UpperTorso",
    "Torso",
    "All Body",
}

function Hitbox:Initialize(Tab)
    local self = setmetatable({}, Hitbox)

    self.Enabled = false
    self.Size = 10
    self.Transparency = 0.7
    self.ColorEnabled = true
    self.Color = Color3.fromRGB(0, 105, 255)
    self.MatEnabled = true
    self.TeamCheck = false
    self.TargetPart = "HumanoidRootPart"

    self.fakeParts = {}
    self.connections = {}

    local HitboxGroup = Tab:AddRightGroupbox("Hitbox Expander")

    local HitboxToggle = HitboxGroup:AddToggle("HitboxEnabled", {
        Text = "Enable Hitbox Expander",
        Default = false,
        Callback = function(v)
            self.Enabled = v
            if v then self:Start() else self:Stop() end
        end
    })

    HitboxToggle:AddKeyPicker("HitboxKeybind", {
        Text = "Hitbox Keybind",
        Default = "H",
        Mode = "Toggle",
        SyncToggleState = true,
        Callback = function(v)
            self.Enabled = v
            if v then self:Start() else self:Stop() end
        end
    })

    HitboxGroup:AddToggle("HitboxTeamCheck", {
        Text = "Team Check",
        Default = false,
        Callback = function(v)
            self.TeamCheck = v
        end
    })

    HitboxGroup:AddDropdown("HitboxTargetPart", {
        Values = PART_OPTIONS,
        Default = "HumanoidRootPart",
        Text = "Target Part",
        Callback = function(v)
            self.TargetPart = v
            if self.Enabled then
                self:DestroyAllFakes()
                self:SpawnAllFakes()
            end
        end
    })

    HitboxGroup:AddSlider("HitboxSize", {
        Text = "Hitbox Size",
        Default = 10,
        Min = 1,
        Max = 15,
        Rounding = 0,
        Callback = function(v)
            self.Size = v
            self:UpdateAllFakeSizes()
        end
    })

    HitboxGroup:AddSlider("HitboxTransparency", {
        Text = "Transparency",
        Default = 0.7,
        Min = 0,
        Max = 1,
        Rounding = 2,
        Callback = function(v)
            self.Transparency = v
            self:UpdateAllFakeSizes()
        end
    })

    HitboxGroup:AddDivider()

    HitboxGroup:AddToggle("HitboxColorEnabled", {
        Text = "Custom Color",
        Default = true,
        Callback = function(v)
            self.ColorEnabled = v
            self:UpdateAllFakeSizes()
        end
    })

    HitboxGroup:AddLabel("Hitbox Color"):AddColorPicker("HitboxColor", {
        Default = Color3.fromRGB(0, 105, 255),
        Callback = function(v)
            self.Color = v
            self:UpdateAllFakeSizes()
        end
    })

    HitboxGroup:AddToggle("HitboxMaterialEnabled", {
        Text = "Neon Material",
        Default = true,
        Callback = function(v)
            self.MatEnabled = v
            self:UpdateAllFakeSizes()
        end
    })

    return self
end

function Hitbox:GetTargetPartNames(character)
    if self.TargetPart == "All Body" then
        local names = {}
        for _, obj in ipairs(character:GetChildren()) do
            if obj:IsA("BasePart") and obj.Name ~= "HumanoidRootPart" then
                table.insert(names, obj.Name)
            end
        end
        return names
    else
        return { self.TargetPart }
    end
end

function Hitbox:IsTeammate(player)
    if not self.TeamCheck then return false end
    local lp = Players.LocalPlayer
    return player.Team ~= nil and lp.Team ~= nil and player.Team == lp.Team
end

function Hitbox:CreateFakePart(player, part)
    local uid = player.UserId
    if not self.fakeParts[uid] then self.fakeParts[uid] = {} end

    local existing = self.fakeParts[uid][part.Name]
    if existing and existing.Parent then return end

    local fake = Instance.new("Part")
    fake.Name = "_DeepHB_" .. part.Name
    fake.Size = Vector3.new(self.Size, self.Size, self.Size)
    fake.Transparency = self.Transparency
    fake.CanCollide = false
    fake.CanTouch = true
    fake.Massless = true
    fake.Anchored = false
    fake.CastShadow = false
    fake.Color = self.ColorEnabled and self.Color or Color3.fromRGB(255, 255, 255)
    fake.Material = self.MatEnabled and Enum.Material.Neon or Enum.Material.Plastic
    fake.Parent = player.Character

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = part
    weld.Part1 = fake
    weld.Parent = fake

    self.fakeParts[uid][part.Name] = fake
end

function Hitbox:SpawnFakesForPlayer(player)
    if not player.Character then return end
    if self:IsTeammate(player) then return end

    local hum = player.Character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    local names = self:GetTargetPartNames(player.Character)
    for _, name in ipairs(names) do
        local part = player.Character:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            pcall(function() self:CreateFakePart(player, part) end)
        end
    end
end

function Hitbox:DestroyFakesForPlayer(player)
    local uid = player.UserId
    if not self.fakeParts[uid] then return end
    for _, fake in pairs(self.fakeParts[uid]) do
        pcall(function()
            if fake and fake.Parent then fake:Destroy() end
        end)
    end
    self.fakeParts[uid] = nil
end

function Hitbox:DestroyAllFakes()
    for _, player in ipairs(Players:GetPlayers()) do
        self:DestroyFakesForPlayer(player)
    end
    self.fakeParts = {}
end

function Hitbox:SpawnAllFakes()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            self:SpawnFakesForPlayer(player)
        end
    end
end

function Hitbox:UpdateAllFakeSizes()
    if not self.Enabled then return end
    for uid, parts in pairs(self.fakeParts) do
        for _, fake in pairs(parts) do
            pcall(function()
                if fake and fake.Parent then
                    fake.Size = Vector3.new(self.Size, self.Size, self.Size)
                    fake.Transparency = self.Transparency
                    fake.Color = self.ColorEnabled and self.Color or Color3.fromRGB(255, 255, 255)
                    fake.Material = self.MatEnabled and Enum.Material.Neon or Enum.Material.Plastic
                end
            end)
        end
    end
end

function Hitbox:DisconnectAll()
    for _, c in ipairs(self.connections) do
        pcall(function() c:Disconnect() end)
    end
    self.connections = {}
end

function Hitbox:Start()
    self:Stop()

    self:SpawnAllFakes()

    local addedConn = Players.PlayerAdded:Connect(function(player)
        if not self.Enabled then return end
        local charConn
        charConn = player.CharacterAdded:Connect(function()
            task.wait(0.5)
            if self.Enabled then
                self:DestroyFakesForPlayer(player)
                self:SpawnFakesForPlayer(player)
            end
        end)
        table.insert(self.connections, charConn)
        task.wait(1)
        if self.Enabled then self:SpawnFakesForPlayer(player) end
    end)
    table.insert(self.connections, addedConn)

    local removedConn = Players.PlayerRemoving:Connect(function(player)
        self:DestroyFakesForPlayer(player)
    end)
    table.insert(self.connections, removedConn)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local charConn = player.CharacterAdded:Connect(function()
                task.wait(0.5)
                if self.Enabled then
                    self:DestroyFakesForPlayer(player)
                    self:SpawnFakesForPlayer(player)
                end
            end)
            table.insert(self.connections, charConn)
        end
    end

    local heartbeat = RunService.Heartbeat:Connect(function()
        if not self.Enabled then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player == Players.LocalPlayer then continue end
            if not player.Character then continue end
            if self:IsTeammate(player) then continue end

            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then continue end

            local uid = player.UserId
            local names = self:GetTargetPartNames(player.Character)
            for _, name in ipairs(names) do
                local fake = self.fakeParts[uid] and self.fakeParts[uid][name]
                if not fake or not fake.Parent then
                    local part = player.Character:FindFirstChild(name)
                    if part and part:IsA("BasePart") then
                        pcall(function() self:CreateFakePart(player, part) end)
                    end
                end
            end
        end
    end)
    table.insert(self.connections, heartbeat)
end

function Hitbox:Stop()
    self:DisconnectAll()
    self:DestroyAllFakes()
end

function Hitbox:Cleanup()
    self.Enabled = false
    self:Stop()
end

return Hitbox
