local ESP = {}
ESP.__index = ESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local GuiInset = game:GetService("GuiService"):GetGuiInset()

local Vertices = {
    { -0.5, -0.5, -0.5 }, { -0.5, 0.5, -0.5 }, { 0.5, -0.5, -0.5 }, { 0.5, 0.5, -0.5 },
    { -0.5, -0.5, 0.5 }, { -0.5, 0.5, 0.5 }, { 0.5, -0.5, 0.5 }, { 0.5, 0.5, 0.5 }
}

local Increase = Vector3.new(2, 2, 2)
local ChamsOffset = Vector3.new(0.01, 0.01, 0.01)
local MatAttr = tostring({}):sub(math.random(8, 12))

local Fonts = {
    ["SourceSans"] = Enum.Font.SourceSans,
    ["SourceSans Bold"] = Enum.Font.SourceSansBold,
    ["Gotham"] = Enum.Font.GothamSSm,
    ["Gotham Bold"] = Enum.Font.GothamBold,
    ["Minecraft"] = Enum.Font.Minecraft,
    ["Cartoon"] = Enum.Font.Cartoon,
}

local function deepCopy(t)
    if type(t) ~= "table" then return t end
    local r = {}
    for k, v in pairs(t) do
        if type(v) == "table" then r[k] = deepCopy(v)
        elseif type(v) == "Color3" then r[k] = Color3.new(v.R, v.G, v.B)
        else r[k] = v end
    end
    return r
end

local function defaultConfig()
    return {
        Box = { Enabled = false, Inline = Color3.fromRGB(0, 0, 0), Outline = Color3.fromRGB(0, 0, 0),
            Gradient = { Color1 = Color3.fromRGB(255, 255, 255), Color2 = Color3.fromRGB(255, 255, 255), Color3 = Color3.fromRGB(255, 255, 255) },
            Filled = { Enabled = false,
                Gradient = { Color1 = Color3.fromRGB(255, 255, 255), Color2 = Color3.fromRGB(255, 255, 255), Color3 = Color3.fromRGB(255, 255, 255),
                    Rotation = { Amount = 45, Moving = { Enabled = false, Speed = 300 } } } } },
        Text = { Font = "SourceSans Bold",
            Name = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Type = "DisplayName", Casing = "lowercase" },
            Weapon = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Casing = "lowercase" },
            Distance = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Casing = "lowercase" } },
        Bars = { Resize = false, Width = 2.5, Lerp = 0.05, Type = "Gradient",
            Health = { Enabled = false, Color1 = Color3.fromRGB(0, 255, 0), Color2 = Color3.fromRGB(255, 255, 0), Color3 = Color3.fromRGB(255, 0, 0) },
            Armor = { Enabled = false, Color1 = Color3.fromRGB(0, 0, 255), Color2 = Color3.fromRGB(135, 206, 235), Color3 = Color3.fromRGB(1, 0, 0), Armored = false } },
        Material = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.ForceField },
        Highlight = { Enabled = false, BehindWalls = false, Color = Color3.fromRGB(255, 255, 255), Outline = Color3.fromRGB(0, 0, 0) },
        Chams = { Enabled = false, BehindWalls = false, Color = Color3.fromRGB(255, 255, 255) },
        Enabled = false
    }
end

local function GetCase(text, caseType)
    caseType = caseType or "lowercase"
    if caseType == "UPPERCASE" then return text:upper()
    elseif caseType == "lowercase" then return text:lower() end
    return text
end

local function GetBodyParts(Character)
    local Parts = {}
    for _, Child in ipairs(Character:GetChildren()) do
        if Child:IsA("BasePart") and Child.Name ~= "HumanoidRootPart" then
            Parts[#Parts + 1] = Child
        end
    end
    return Parts
end

local function CustomBounds(Model)
    local MinB = Vector3.new(math.huge, math.huge, math.huge)
    local MaxB = Vector3.new(-math.huge, -math.huge, -math.huge)
    for _, Part in ipairs(Model:GetChildren()) do
        if Part:IsA("BasePart") then
            local CF, Size = Part.CFrame, Part.Size
            for _, V in ipairs(Vertices) do
                local WS = CF:PointToWorldSpace(Vector3.new(V[1] * Size.X, (V[2] + 0.2) * (Size.Y + 0.2), V[3] * Size.Z))
                MinB = Vector3.new(math.min(MinB.X, WS.X), math.min(MinB.Y, WS.Y), math.min(MinB.Z, WS.Z))
                MaxB = Vector3.new(math.max(MaxB.X, WS.X), math.max(MaxB.Y, WS.Y), math.max(MaxB.Z, WS.Z))
            end
        end
    end
    if MinB == Vector3.new(math.huge, math.huge, math.huge) then return end
    local Center = (MinB + MaxB) / 2
    return CFrame.new(Center), MaxB - MinB + Increase, Center
end

function ESP:Initialize(Tab)
    local self = setmetatable({}, ESP)
    self.Config = defaultConfig()
    self.Cache = {}
    self.RotationAngle = -45
    self.LastTick = tick()
    self.PlayerAddedConn = nil
    self.PlayerRemovingConn = nil
    self.HeartbeatConn = nil
    self:CreateUI(Tab)
    self:SetupConnections()
    return self
end

function ESP:MakeText()
    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0, 4, 0, 4)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextStrokeTransparency = 0
    Label.TextScaled = false
    Label.TextSize = 10
    Label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    Label.FontFace = Fonts[self.Config.Text.Font]
    Label.Text = ""
    return Label
end

function ESP:CreateBox(Parent, PlayerName)
    local BoxContainer = Instance.new("Frame")
    BoxContainer.Name = "BoxContainer_" .. PlayerName
    BoxContainer.BackgroundTransparency = 1
    BoxContainer.BorderSizePixel = 0
    BoxContainer.Parent = Parent

    local BoxFrame = Instance.new("Frame")
    BoxFrame.Name = "Box_" .. PlayerName
    BoxFrame.Size = UDim2.new(1, 0, 1, 0)
    BoxFrame.Position = UDim2.new(0, 0, 0, 0)
    BoxFrame.BackgroundTransparency = 1
    BoxFrame.BorderSizePixel = 0
    BoxFrame.Parent = BoxContainer

    local Stroke = Instance.new("UIStroke")
    Stroke.Name = "Stroke"
    Stroke.Thickness = 2
    Stroke.Color = Color3.fromRGB(255, 255, 255)
    Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    Stroke.Parent = BoxFrame

    local BoxGradient = Instance.new("UIGradient")
    BoxGradient.Name = "Gradient"
    BoxGradient.Rotation = 45
    BoxGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    BoxGradient.Parent = Stroke

    local FillFrame = Instance.new("Frame")
    FillFrame.Name = "BoxFill"
    FillFrame.Size = UDim2.new(1, 0, 1, 0)
    FillFrame.Position = UDim2.new(0, 0, 0, 0)
    FillFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    FillFrame.BackgroundTransparency = 0.5
    FillFrame.BorderSizePixel = 0
    FillFrame.Visible = false
    FillFrame.Parent = BoxContainer

    local FillGradient = Instance.new("UIGradient")
    FillGradient.Name = "FillGradient"
    FillGradient.Rotation = 45
    FillGradient.Parent = FillFrame

    return { Box = BoxContainer, Stroke = Stroke, Gradient = BoxGradient, Fill = FillFrame, FillGradient = FillGradient }
end

function ESP:CreateHighlight(Player, Character)
    local existing = self.Cache[Player] and self.Cache[Player].Highlight
    if existing then existing:Destroy() end
    local H = Instance.new("Highlight")
    H.FillColor = self.Config.Highlight.Color
    H.OutlineColor = self.Config.Highlight.Outline
    H.DepthMode = self.Config.Highlight.BehindWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    H.Enabled = true
    H.Adornee = Character
    H.Parent = CoreGui
    if self.Cache[Player] then self.Cache[Player].Highlight = H end
end

function ESP:UpdateHighlight(Player, Character)
    local H = self.Cache[Player] and self.Cache[Player].Highlight
    if not H then return end
    H.Adornee = nil; H.Parent = nil; H.Adornee = Character; H.Parent = CoreGui
end

function ESP:RemoveHighlight(Player)
    local H = self.Cache[Player] and self.Cache[Player].Highlight
    if H then H:Destroy(); self.Cache[Player].Highlight = nil end
end

function ESP:CreateChams(Player, Character)
    self:RemoveChams(Player)
    local list = {}
    local ZIndex = self.Config.Chams.BehindWalls and 1 or -1
    for _, Part in ipairs(GetBodyParts(Character)) do
        local Box = Instance.new("BoxHandleAdornment")
        Box.Visible = true; Box.Adornee = Part; Box.Color3 = self.Config.Chams.Color
        Box.ZIndex = ZIndex; Box.AlwaysOnTop = self.Config.Chams.BehindWalls
        Box.Size = Part.Size + ChamsOffset; Box.Archivable = true; Box.Parent = CoreGui
        list[#list + 1] = Box
    end
    if self.Cache[Player] then self.Cache[Player].Chams = list end
end

function ESP:UpdateChams(Player, Character)
    self:CreateChams(Player, Character)
end

function ESP:RemoveChams(Player)
    local list = self.Cache[Player] and self.Cache[Player].Chams
    if list then
        for i = 1, #list do list[i]:Destroy(); list[i] = nil end
        self.Cache[Player].Chams = nil
    end
end

function ESP:ApplyMaterial(Player, Character)
    Character = Character or (self.Cache[Player] and self.Cache[Player].Character)
    if not Character then return end
    if not Player:HasAppearanceLoaded() then Player.CharacterAppearanceLoaded:Wait() end
    task.wait(0.2)
    local Mat = self.Config.Material.Material
    local Color = self.Config.Material.Color
    for _, Part in ipairs(GetBodyParts(Character)) do
        Part.Material = Mat; Part.Color = Color
        if Part.Transparency ~= 1 then Part.Transparency = 0.5 end
    end
    for _, Obj in ipairs(Character:GetDescendants()) do
        if Obj.ClassName == "Accessory" then
            local Handle = Obj:FindFirstChild("Handle")
            if Handle and Handle.ClassName == "MeshPart" then
                if not Handle:GetAttribute(MatAttr) then Handle:SetAttribute(MatAttr, Handle.TextureID) end
                Handle.Material = Mat; Handle.TextureID = ""; Handle.Color = Color
            end
        end
    end
    local function strip(cl, attr, prop)
        if cl and cl[prop] ~= "" then cl:SetAttribute(attr, cl[prop]); cl[prop] = "" end
    end
    strip(Character:FindFirstChildOfClass("Shirt"), "_OrigShirt", "ShirtTemplate")
    strip(Character:FindFirstChildOfClass("Pants"), "_OrigPants", "PantsTemplate")
    strip(Character:FindFirstChildOfClass("ShirtGraphic"), "_OrigGraphic", "Graphic")
end

function ESP:RemoveMaterial(Player, Character)
    Character = Character or (self.Cache[Player] and self.Cache[Player].Character)
    if not Character then return end
    for _, Part in ipairs(GetBodyParts(Character)) do
        Part.Material = Enum.Material.SmoothPlastic
        if Part.Transparency ~= 1 then Part.Transparency = 0 end
    end
    for _, Obj in ipairs(Character:GetDescendants()) do
        if Obj.ClassName == "Accessory" then
            local Handle = Obj:FindFirstChild("Handle")
            if Handle and Handle.ClassName == "MeshPart" then
                local Orig = Handle:GetAttribute(MatAttr)
                if Orig then Handle.TextureID = Orig; Handle:SetAttribute(MatAttr, nil) end
                Handle.Material = Enum.Material.SmoothPlastic; Handle.Transparency = 0
            end
        end
    end
    local function restore(cl, attr, prop)
        if cl then local o = cl:GetAttribute(attr); if o then cl[prop] = o; cl:SetAttribute(attr, nil) end end
    end
    restore(Character:FindFirstChildOfClass("Shirt"), "_OrigShirt", "ShirtTemplate")
    restore(Character:FindFirstChildOfClass("Pants"), "_OrigPants", "PantsTemplate")
    restore(Character:FindFirstChildOfClass("ShirtGraphic"), "_OrigGraphic", "Graphic")
end

function ESP:Render(Player)
    if not Player then return end
    self.Cache[Player] = self.Cache[Player] or {}
    self.Cache[Player].Box = {}; self.Cache[Player].Bars = {}; self.Cache[Player].Text = {}
    self.Cache[Player].Highlight = nil; self.Cache[Player].Chams = nil
    self.Cache[Player].Character = Player.Character; self.Cache[Player].CharAddedConn = nil

    local BoxGui = Instance.new("ScreenGui")
    BoxGui.Name = Player.Name .. "_BoxESP"; BoxGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; BoxGui.Parent = CoreGui
    self.Cache[Player].Box.Full = self:CreateBox(BoxGui, Player.Name)

    local function makeTG() local g = Instance.new("ScreenGui"); g.Parent = CoreGui; return g end
    self.Cache[Player].Text.Distance = self:MakeText(); self.Cache[Player].Text.Distance.Parent = makeTG()
    self.Cache[Player].Text.Weapon = self:MakeText(); self.Cache[Player].Text.Weapon.Parent = makeTG()
    self.Cache[Player].Text.Name = self:MakeText(); self.Cache[Player].Text.Name.Parent = makeTG()

    local function makeBar(c1, c2, c3)
        local gui = Instance.new("ScreenGui"); gui.Name = Player.Name .. "_Bar"
        gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; gui.Parent = CoreGui
        local ol = Instance.new("Frame"); ol.BackgroundColor3 = Color3.new(0, 0, 0)
        ol.BorderSizePixel = 0; ol.Name = "Outline"; ol.Parent = gui
        local fi = Instance.new("Frame"); fi.BackgroundTransparency = 0; fi.BorderSizePixel = 0
        fi.Name = "Fill"; fi.Parent = ol
        local gr = Instance.new("UIGradient", fi)
        gr.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, c1), ColorSequenceKeypoint.new(0.5, c2), ColorSequenceKeypoint.new(1, c3)})
        gr.Rotation = 90
        return { Gui = gui, Outline = ol, Frame = fi, Gradient = gr, Tick = tick(), Rotation = 90 }
    end

    self.Cache[Player].Bars.Health = makeBar(self.Config.Bars.Health.Color1, self.Config.Bars.Health.Color2, self.Config.Bars.Health.Color3)
    self.Cache[Player].Bars.Armor = makeBar(self.Config.Bars.Armor.Color1, self.Config.Bars.Armor.Color2, self.Config.Bars.Armor.Color3)

    local Char = Player.Character
    if Char then
        if self.Config.Highlight.Enabled then self:CreateHighlight(Player, Char) end
        if self.Config.Chams.Enabled then self:CreateChams(Player, Char) end
        if self.Config.Material.Enabled then task.spawn(self.ApplyMaterial, self, Player, Char) end
    end

    self.Cache[Player].CharAddedConn = Player.CharacterAdded:Connect(function(NewChar)
        self.Cache[Player].Character = NewChar
        if self.Config.Highlight.Enabled then self:UpdateHighlight(Player, NewChar) end
        if self.Config.Chams.Enabled then self:UpdateChams(Player, NewChar) end
        if self.Config.Material.Enabled then task.spawn(self.ApplyMaterial, self, Player, NewChar) end
    end)
end

function ESP:ClearEsp(Player)
    if not self.Cache[Player] then return end
    if self.Cache[Player].Box and self.Cache[Player].Box.Full and self.Cache[Player].Box.Full.Box then
        self.Cache[Player].Box.Full.Box.Visible = false
    end
    if self.Cache[Player].Text then
        if self.Cache[Player].Text.Distance then self.Cache[Player].Text.Distance.Visible = false end
        if self.Cache[Player].Text.Weapon then self.Cache[Player].Text.Weapon.Visible = false end
        if self.Cache[Player].Text.Name then self.Cache[Player].Text.Name.Visible = false end
    end
    if self.Cache[Player].Bars then
        for _, bt in ipairs({"Health", "Armor"}) do
            local bar = self.Cache[Player].Bars[bt]
            if bar and bar.Frame then bar.Frame.Visible = false; bar.Outline.Visible = false end
        end
    end
    self:RemoveHighlight(Player); self:RemoveChams(Player)
    if self.Cache[Player].CharAddedConn then self.Cache[Player].CharAddedConn:Disconnect() end
end

function ESP:DestroyPlayer(Player)
    if not self.Cache[Player] then return end
    if self.Cache[Player].Box and self.Cache[Player].Box.Full and self.Cache[Player].Box.Full.Box then
        pcall(function() self.Cache[Player].Box.Full.Box.Parent:Destroy() end)
    end
    if self.Cache[Player].Text then
        for _, ln in ipairs({"Name", "Weapon", "Distance"}) do
            local lbl = self.Cache[Player].Text[ln]
            if lbl then pcall(function() lbl.Parent:Destroy() end) end
        end
    end
    if self.Cache[Player].Bars then
        for _, bt in ipairs({"Health", "Armor"}) do
            local bar = self.Cache[Player].Bars[bt]
            if bar and bar.Gui then pcall(function() bar.Gui:Destroy() end) end
        end
    end
    self:RemoveHighlight(Player); self:RemoveChams(Player)
    if self.Cache[Player].CharAddedConn then self.Cache[Player].CharAddedConn:Disconnect() end
    self.Cache[Player] = nil
end

function ESP:DestroyAll()
    for Player, _ in pairs(self.Cache) do
        if Player then self:DestroyPlayer(Player) end
    end
    self.Cache = {}
end

function ESP:Update(Player)
    if not Player or not self.Cache[Player] then return end
    local Character = Player.Character
    local Camera = workspace.CurrentCamera
    if not Character or not Camera then return end

    local RootPart = Character:FindFirstChild("HumanoidRootPart")
    local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
    if not RootPart or not Humanoid then self:ClearEsp(Player); return end

    local CF, Size3D, Center = CustomBounds(Character)
    if not CF then self:ClearEsp(Player); return end

    local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Center)
    if not OnScreen then self:ClearEsp(Player); return end

    local Distance = (Camera.CFrame.Position - Center).Magnitude
    local Height = math.tan(math.rad(Camera.FieldOfView / 2)) * 2 * Distance
    local Scale = Vector2.new((Camera.ViewportSize.Y / Height) * Size3D.X, (Camera.ViewportSize.Y / Height) * Size3D.Y)
    local Position = Vector2.new(ScreenPos.X - Scale.X / 2, ScreenPos.Y - Scale.Y / 2)

    local PC = self.Cache[Player]
    local FullBox = PC.Box.Full
    local C = self.Config

    local HL = PC.Highlight
    if C.Highlight.Enabled then
        if not HL then self:CreateHighlight(Player, Character); HL = PC.Highlight end
        if HL then
            HL.FillColor = C.Highlight.Color; HL.OutlineColor = C.Highlight.Outline
            HL.DepthMode = C.Highlight.BehindWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            HL.Enabled = true
        end
    elseif HL then HL.Enabled = false end

    local Cham = PC.Chams
    if C.Chams.Enabled then
        if not Cham then self:CreateChams(Player, Character); Cham = PC.Chams end
        if Cham then
            local Z = C.Chams.BehindWalls and 1 or -1
            for i = 1, #Cham do Cham[i].Color3 = C.Chams.Color; Cham[i].ZIndex = Z; Cham[i].AlwaysOnTop = C.Chams.BehindWalls end
        end
    elseif Cham then self:RemoveChams(Player) end

    if C.Box.Enabled and FullBox.Box then
        FullBox.Box.Visible = true
        FullBox.Box.Position = UDim2.new(0, Position.X, 0, Position.Y - GuiInset.Y)
        FullBox.Box.Size = UDim2.new(0, Scale.X, 0, Scale.Y)
        if FullBox.Stroke then FullBox.Stroke.Thickness = 2 end
        if FullBox.Gradient then
            FullBox.Gradient.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, C.Box.Gradient.Color1),
                ColorSequenceKeypoint.new(0.5, C.Box.Gradient.Color2),
                ColorSequenceKeypoint.new(1, C.Box.Gradient.Color3)
            })
        end
        if C.Box.Filled.Enabled and FullBox.Fill then
            FullBox.Fill.Visible = true
            if FullBox.FillGradient then
                FullBox.FillGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, C.Box.Filled.Gradient.Color1),
                    ColorSequenceKeypoint.new(0.5, C.Box.Filled.Gradient.Color2),
                    ColorSequenceKeypoint.new(1, C.Box.Filled.Gradient.Color3)
                })
                if C.Box.Filled.Gradient.Rotation.Moving.Enabled then
                    local now = tick(); local dt = now - self.LastTick
                    self.RotationAngle = self.RotationAngle + dt * C.Box.Filled.Gradient.Rotation.Moving.Speed
                    FullBox.FillGradient.Rotation = self.RotationAngle % 360; self.LastTick = now
                else
                    FullBox.FillGradient.Rotation = C.Box.Filled.Gradient.Rotation.Amount
                end
            end
        elseif FullBox.Fill then FullBox.Fill.Visible = false end
    elseif FullBox.Box then FullBox.Box.Visible = false end

    local BarHeight = Scale.Y; local BarWidth = C.Bars.Width; local BaseX = Position.X; local Y = Position.Y - GuiInset.Y
    local hpVis = false

    if C.Bars.Health.Enabled and Humanoid then
        local Target = math.clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1)
        local Last = PC.Bars.Health.LastHealth or Target
        local Lerped = Last + (Target - Last) * C.Bars.Lerp; PC.Bars.Health.LastHealth = Lerped
        local X = BaseX - (BarWidth + 4)
        local Ol = PC.Bars.Health.Outline; local Fi = PC.Bars.Health.Frame
        if Ol and Fi then
            hpVis = true; Ol.Visible = true
            if C.Bars.Resize then
                local h = math.max(BarHeight * Lerped, 2)
                Ol.Position = UDim2.new(0, X - 1, 0, Y + BarHeight - h - 1); Ol.Size = UDim2.new(0, BarWidth + 2, 0, h + 2)
                Fi.Visible = true; Fi.Position = UDim2.new(0, 1, 0, 1); Fi.Size = UDim2.new(0, BarWidth, 0, h)
            else
                Ol.Position = UDim2.new(0, X - 1, 0, Y - 1); Ol.Size = UDim2.new(0, BarWidth + 2, 0, BarHeight + 2)
                Fi.Visible = true; Fi.Position = UDim2.new(0, 1, 0, (1 - Lerped) * BarHeight + 1)
                Fi.Size = UDim2.new(0, BarWidth, 0, Lerped * BarHeight)
            end
            Ol.BackgroundTransparency = 0.2
            if PC.Bars.Health.Gradient then
                if C.Bars.Type == "Gradient" then
                    PC.Bars.Health.Gradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, C.Bars.Health.Color1), ColorSequenceKeypoint.new(0.5, C.Bars.Health.Color2), ColorSequenceKeypoint.new(1, C.Bars.Health.Color3)
                    })
                else PC.Bars.Health.Gradient.Color = ColorSequence.new(C.Bars.Health.Color1) end
            end
        end
    else
        if PC.Bars.Health.Outline then PC.Bars.Health.Outline.Visible = false end
        if PC.Bars.Health.Frame then PC.Bars.Health.Frame.Visible = false end
    end

    if C.Bars.Armor.Enabled and Character then
        local BE = Character:FindFirstChild("BodyEffects")
        local Av = BE and BE:FindFirstChild("Armor")
        local ArmorVal = Av and Av.Value or 0
        local Target = math.clamp(ArmorVal / 130, 0, 1)
        local Show = not C.Bars.Armor.Armored or ArmorVal > 0
        if Show then
            local Last = PC.Bars.Armor.LastArmor or Target
            local Lerped = Last + (Target - Last) * C.Bars.Lerp; PC.Bars.Armor.LastArmor = Lerped
            local X = hpVis and (BaseX - (BarWidth * 2 + 8)) or (BaseX - (BarWidth + 4))
            local Ol = PC.Bars.Armor.Outline; local Fi = PC.Bars.Armor.Frame
            if Ol and Fi then
                Ol.Visible = true
                if C.Bars.Resize then
                    local h = math.max(BarHeight * Lerped, 2)
                    Ol.Position = UDim2.new(0, X - 1, 0, Y + BarHeight - h - 1); Ol.Size = UDim2.new(0, BarWidth + 2, 0, h + 2)
                    Fi.Visible = true; Fi.Position = UDim2.new(0, 1, 0, 1); Fi.Size = UDim2.new(0, BarWidth, 0, h)
                else
                    Ol.Position = UDim2.new(0, X - 1, 0, Y - 1); Ol.Size = UDim2.new(0, BarWidth + 2, 0, BarHeight + 2)
                    Fi.Visible = true; Fi.Position = UDim2.new(0, 1, 0, (1 - Lerped) * BarHeight + 1)
                    Fi.Size = UDim2.new(0, BarWidth, 0, Lerped * BarHeight)
                end
                Ol.BackgroundTransparency = 0.2
                if PC.Bars.Armor.Gradient then
                    if C.Bars.Type == "Gradient" then
                        PC.Bars.Armor.Gradient.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, C.Bars.Armor.Color1), ColorSequenceKeypoint.new(0.5, C.Bars.Armor.Color2), ColorSequenceKeypoint.new(1, C.Bars.Armor.Color3)
                        })
                    else PC.Bars.Armor.Gradient.Color = ColorSequence.new(C.Bars.Armor.Color1) end
                end
            end
        else
            if PC.Bars.Armor.Outline then PC.Bars.Armor.Outline.Visible = false end
            if PC.Bars.Armor.Frame then PC.Bars.Armor.Frame.Visible = false end
        end
    else
        if PC.Bars.Armor.Outline then PC.Bars.Armor.Outline.Visible = false end
        if PC.Bars.Armor.Frame then PC.Bars.Armor.Frame.Visible = false end
    end

    local NL = PC.Text.Name; local WL = PC.Text.Weapon; local DL = PC.Text.Distance
    local BXT = Position.X + (Scale.X / 2); local BY = Position.Y - GuiInset.Y

    if C.Text.Name.Enabled then
        NL.Visible = true
        NL.Position = UDim2.new(0, BXT - (NL.AbsoluteSize.X / 2), 0, BY - 15 + 6)
        NL.TextColor3 = C.Text.Name.Color; NL.FontFace = Fonts[C.Text.Font]
        NL.Text = GetCase(C.Text.Name.Type == "DisplayName" and Player.DisplayName or Player.Name, C.Text.Name.Casing)
    else NL.Visible = false end

    local WP, DP
    if C.Text.Weapon.Enabled and C.Text.Distance.Enabled then WP = BY + Scale.Y + 2; DP = BY + Scale.Y + 14
    elseif C.Text.Weapon.Enabled then WP = BY + Scale.Y + 2
    elseif C.Text.Distance.Enabled then DP = BY + Scale.Y + 2 end

    if C.Text.Weapon.Enabled then
        WL.Visible = true; WL.Position = UDim2.new(0, BXT - (WL.AbsoluteSize.X / 2), 0, WP)
        WL.TextColor3 = C.Text.Weapon.Color; WL.FontFace = Fonts[C.Text.Font]
        local Tool = Character:FindFirstChildOfClass("Tool")
        WL.Text = GetCase((Tool and Tool.Name) or "None", C.Text.Weapon.Casing)
    else WL.Visible = false end

    if C.Text.Distance.Enabled then
        DL.Visible = true; DL.Position = UDim2.new(0, BXT - (DL.AbsoluteSize.X / 2), 0, DP)
        DL.TextColor3 = C.Text.Distance.Color; DL.FontFace = Fonts[C.Text.Font]
        DL.Text = GetCase(string.format("[%.0f]", Distance * 0.28), C.Text.Distance.Casing)
    else DL.Visible = false end
end

function ESP:SetupConnections()
    self:TeardownConnections()
    self.PlayerAddedConn = Players.PlayerAdded:Connect(function(Player)
        if Player ~= Players.LocalPlayer and self.Config.Enabled then self:Render(Player) end
    end)
    self.PlayerRemovingConn = Players.PlayerRemoving:Connect(function(Player)
        if Player ~= Players.LocalPlayer then self:DestroyPlayer(Player) end
    end)
    self.HeartbeatConn = RunService.Heartbeat:Connect(function()
        if not self.Config.Enabled then return end
        for Player, _ in pairs(self.Cache) do if Player then self:Update(Player) end end
    end)
end

function ESP:TeardownConnections()
    if self.PlayerAddedConn then self.PlayerAddedConn:Disconnect(); self.PlayerAddedConn = nil end
    if self.PlayerRemovingConn then self.PlayerRemovingConn:Disconnect(); self.PlayerRemovingConn = nil end
    if self.HeartbeatConn then self.HeartbeatConn:Disconnect(); self.HeartbeatConn = nil end
end

function ESP:CreateUI(Tab)
    local S = self.Config
    local Left = Tab:AddLeftGroupbox("Player ESP", "eye")

    local BoxTog = Left:AddToggle("ESPBox", { Text = "Box", Default = false, Callback = function(v) S.Box.Enabled = v end })
    BoxTog:AddColorPicker("BoxColor1", { Default = S.Box.Gradient.Color1, Callback = function(v) S.Box.Gradient.Color1 = v end })
    BoxTog:AddColorPicker("BoxColor2", { Default = S.Box.Gradient.Color2, Callback = function(v) S.Box.Gradient.Color2 = v end })
    BoxTog:AddColorPicker("BoxColor3", { Default = S.Box.Gradient.Color3, Callback = function(v) S.Box.Gradient.Color3 = v end })

    local FillTog = Left:AddToggle("ESPFilled", { Text = "Filled Box", Default = false, Callback = function(v) S.Box.Filled.Enabled = v end })
    FillTog:AddColorPicker("FillCol1", { Default = S.Box.Filled.Gradient.Color1, Callback = function(v) S.Box.Filled.Gradient.Color1 = v end })
    FillTog:AddColorPicker("FillCol2", { Default = S.Box.Filled.Gradient.Color2, Callback = function(v) S.Box.Filled.Gradient.Color2 = v end })
    FillTog:AddColorPicker("FillCol3", { Default = S.Box.Filled.Gradient.Color3, Callback = function(v) S.Box.Filled.Gradient.Color3 = v end })

    local HLTog = Left:AddToggle("ESPHighlight", { Text = "Highlight", Default = false, Callback = function(v)
        S.Highlight.Enabled = v; if not v then for p in pairs(self.Cache) do self:RemoveHighlight(p) end end end })
    HLTog:AddColorPicker("HLFill", { Default = S.Highlight.Color, Callback = function(v) S.Highlight.Color = v end })
    HLTog:AddColorPicker("HLOutline", { Default = S.Highlight.Outline, Callback = function(v) S.Highlight.Outline = v end })
    Left:AddToggle("HLBehindWalls", { Text = "Behind Walls", Default = false, Callback = function(v) S.Highlight.BehindWalls = v end })

    local ChamsTog = Left:AddToggle("ESPChams", { Text = "Chams", Default = false, Callback = function(v)
        S.Chams.Enabled = v; if not v then for p in pairs(self.Cache) do self:RemoveChams(p) end end end })
    ChamsTog:AddColorPicker("ChamsColor", { Default = S.Chams.Color, Callback = function(v) S.Chams.Color = v end })
    Left:AddToggle("ChamsBehindWalls", { Text = "Behind Walls", Default = false, Callback = function(v) S.Chams.BehindWalls = v end })

    Left:AddDivider()
    local MatTog = Left:AddToggle("ESPMat", { Text = "Material Override", Default = false, Callback = function(v) S.Material.Enabled = v end })
    MatTog:AddColorPicker("MatCol", { Default = S.Material.Color, Callback = function(v) S.Material.Color = v end })
    Left:AddDropdown("MatType", { Values = {"ForceField", "Neon", "Glass", "SmoothPlastic"}, Default = "ForceField", Text = "Material", Callback = function(v) S.Material.Material = Enum.Material[v] end })

    local Right = Tab:AddRightGroupbox("Text & Bars", "type")
    local NameTog = Right:AddToggle("ESPName", { Text = "Name", Default = false, Callback = function(v) S.Text.Name.Enabled = v end })
    NameTog:AddColorPicker("NameColor", { Default = S.Text.Name.Color, Callback = function(v) S.Text.Name.Color = v end })
    Right:AddDropdown("NameType", { Values = {"DisplayName", "Username"}, Default = "DisplayName", Text = "Type", Callback = function(v) S.Text.Name.Type = v end })
    Right:AddDropdown("NameCasing", { Values = {"lowercase", "UPPERCASE", "Default"}, Default = "lowercase", Text = "Casing", Callback = function(v) S.Text.Name.Casing = v end })

    local WepTog = Right:AddToggle("ESPWeapon", { Text = "Weapon", Default = false, Callback = function(v) S.Text.Weapon.Enabled = v end })
    WepTog:AddColorPicker("WepColor", { Default = S.Text.Weapon.Color, Callback = function(v) S.Text.Weapon.Color = v end })
    Right:AddDropdown("WepCasing", { Values = {"lowercase", "UPPERCASE", "Default"}, Default = "lowercase", Text = "Casing", Callback = function(v) S.Text.Weapon.Casing = v end })

    local DistTog = Right:AddToggle("ESPDist", { Text = "Distance", Default = false, Callback = function(v) S.Text.Distance.Enabled = v end })
    DistTog:AddColorPicker("DistColor", { Default = S.Text.Distance.Color, Callback = function(v) S.Text.Distance.Color = v end })
    Right:AddDropdown("DistCasing", { Values = {"lowercase", "UPPERCASE", "Default"}, Default = "lowercase", Text = "Casing", Callback = function(v) S.Text.Distance.Casing = v end })

    Right:AddDropdown("ESPFont", { Values = {"SourceSans", "SourceSans Bold", "Gotham", "Gotham Bold", "Minecraft", "Cartoon"}, Default = "SourceSans Bold", Text = "Font", Callback = function(v) S.Text.Font = v end })
    Right:AddDivider()

    local HpTog = Right:AddToggle("ESPHealth", { Text = "Health Bar", Default = false, Callback = function(v) S.Bars.Health.Enabled = v end })
    HpTog:AddColorPicker("HpHigh", { Default = S.Bars.Health.Color1, Callback = function(v) S.Bars.Health.Color1 = v end })
    HpTog:AddColorPicker("HpMid", { Default = S.Bars.Health.Color2, Callback = function(v) S.Bars.Health.Color2 = v end })
    HpTog:AddColorPicker("HpLow", { Default = S.Bars.Health.Color3, Callback = function(v) S.Bars.Health.Color3 = v end })

    local ArmorTog = Right:AddToggle("ESPArmor", { Text = "Armor Bar", Default = false, Callback = function(v) S.Bars.Armor.Enabled = v end })
    ArmorTog:AddColorPicker("ArmorC1", { Default = S.Bars.Armor.Color1, Callback = function(v) S.Bars.Armor.Color1 = v end })
    ArmorTog:AddColorPicker("ArmorC2", { Default = S.Bars.Armor.Color2, Callback = function(v) S.Bars.Armor.Color2 = v end })
    ArmorTog:AddColorPicker("ArmorC3", { Default = S.Bars.Armor.Color3, Callback = function(v) S.Bars.Armor.Color3 = v end })
    Right:AddToggle("ArmorOnly", { Text = "Armored Only", Default = false, Callback = function(v) S.Bars.Armor.Armored = v end })

    Right:AddDivider()
    Right:AddSlider("BarWidth", { Text = "Width", Default = 2.5, Min = 1, Max = 10, Rounding = 1, Callback = function(v) S.Bars.Width = v end })
    Right:AddSlider("BarLerp", { Text = "Smoothness", Default = 0.05, Min = 0.01, Max = 0.5, Rounding = 3, Callback = function(v) S.Bars.Lerp = v end })
    Right:AddDropdown("BarType", { Values = {"Gradient", "Solid Color"}, Default = "Gradient", Text = "Bar Type", Callback = function(v) S.Bars.Type = v end })
    Right:AddToggle("BarResize", { Text = "Resize", Default = false, Callback = function(v) S.Bars.Resize = v end })
    Right:AddDivider()

    local mainTog = Right:AddToggle("ESPEnabled", { Text = "Enable ESP", Default = false, Callback = function(v)
        S.Enabled = v
        if v then for _, pl in ipairs(Players:GetPlayers()) do if pl ~= Players.LocalPlayer then self:Render(pl) end end
        else self:DestroyAll() end end })
    mainTog:AddKeyPicker("ESPKeybind", { Text = "Keybind", Default = "None", Mode = "Toggle", SyncToggleState = true, Callback = function(v)
        S.Enabled = v
        if v then for _, pl in ipairs(Players:GetPlayers()) do if pl ~= Players.LocalPlayer then self:Render(pl) end end
        else self:DestroyAll() end end })
end

function ESP:Cleanup()
    self.Config.Enabled = false; self:TeardownConnections(); self:DestroyAll()
end

return ESP
