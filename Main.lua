setfpscap(32555555555555555)

local Config = {
    Box = {
        Enabled = false,
        Inline = Color3.fromRGB(0, 0, 0),
        Outline = Color3.fromRGB(0, 0, 0),
        Gradient = {
            Color1 = Color3.fromRGB(255, 255, 255),
            Color2 = Color3.fromRGB(255, 255, 255),
            Color3 = Color3.fromRGB(255, 255, 255)
        },
        Filled = {
            Enabled = false,
            Gradient = {
                Color1 = Color3.fromRGB(255, 255, 255),
                Color2 = Color3.fromRGB(255, 255, 255),
                Color3 = Color3.fromRGB(255, 255, 255),
                Rotation = {
                    Amount = 45,
                    Moving = {
                        Enabled = false,
                        Speed = 300
                    }
                }
            }
        }
    },
    Text = {
        Font = "Tahoma Bold",
        Name = {
            Enabled = false,
            Color = Color3.fromRGB(255, 255, 255),
            Type = "DisplayName",
            Casing = "lowercase"
        },
        Weapon = {
            Enabled = false,
            Color = Color3.fromRGB(255, 255, 255),
            Casing = "lowercase"
        },
        Distance = {
            Enabled = false,
            Color = Color3.fromRGB(255, 255, 255),
            Casing = "lowercase"
        }
    },
    Bars = {
        Resize = false,
        Width = 2.5,
        Lerp = 0.05,
        Type = "Gradient",
        Health = {
            Enabled = false,
            Color1 = Color3.fromRGB(0, 255, 0),
            Color2 = Color3.fromRGB(255, 255, 0),
            Color3 = Color3.fromRGB(255, 0, 0)
        },
        Armor = {
            Enabled = false,
            Color1 = Color3.fromRGB(0, 0, 255),
            Color2 = Color3.fromRGB(135, 206, 235),
            Color3 = Color3.fromRGB(1, 0, 0),
            Armored = false
        }
    },
    Material = {
        Enabled = false,
        Color = Color3.fromRGB(255, 255, 255),
        Material = Enum.Material.ForceField
    },
    Highlight = {
        Enabled = false,
        BehindWalls = false,
        Color = Color3.fromRGB(255, 255, 255),
        Outline = Color3.fromRGB(0, 0, 0)
    },
    Chams = {
        Enabled = false,
        BehindWalls = false,
        Color = Color3.fromRGB(255, 255, 255)
    }
}

-- Восстанавливаем вырезанные шрифты стандартными средствами Roblox во избежание ошибок
local Fonts = {
    ["Tahoma Bold"] = Font.fromEnum(Enum.Font.RobotoMono)
}

if not LPH_OBFUSCATED then
    LPH_JIT_MAX = function(...)
        return (...)
    end

    LPH_NO_VIRTUALIZE = function(...)
        return (...)
    end
end

local Overlay = {}
local Draw = nil

local GuiInset = game:GetService("GuiService"):GetGuiInset()
local RotationAngle, LastTick = -45, tick()

local Utility, Connections, Cache = {}, {}, {}
Utility.Funcs = Utility.Funcs or {}
local Increase = Vector3.new(2, 2, 2)
local Vertices = { { -0.5, -0.5, -0.5 }, { -0.5, 0.5, -0.5 }, { 0.5, -0.5, -0.5 }, { 0.5, 0.5, -0.5 }, { -0.5, -0.5, 0.5 }, { -0.5, 0.5, 0.5 }, { 0.5, -0.5, 0.5 }, { 0.5, 0.5, 0.5 } }

local ChamsOffset = Vector3.new(0.01, 0.01, 0.01)
local MaterialAttribute = tostring({}):sub(math.random(8, 12))
local CoreGui = game:GetService("CoreGui")

local function GetBodyParts(Character)
    local Parts = {}
    for _, Child in ipairs(Character:GetChildren()) do
        if Child:IsA("BasePart") and Child.Name ~= "HumanoidRootPart" then
            Parts[#Parts + 1] = Child
        end
    end
    return Parts
end

Utility.Funcs.CustomBounds = function(Model)
    local MinBound, MaxBound = Vector3.new(math.huge, math.huge, math.huge), Vector3.new(-math.huge, -math.huge, -math.huge)

    for _, Part in ipairs(Model:GetChildren()) do
        if Part:IsA("BasePart") then
            local CF, Size = Part.CFrame, Part.Size
            for _, V in ipairs(Vertices) do
                local WorldSpace = CF:PointToWorldSpace(Vector3.new(V[1] * Size.X, (V[2] + 0.2) * (Size.Y + 0.2), V[3] * Size.Z))
                MinBound = Vector3.new(math.min(MinBound.X, WorldSpace.X), math.min(MinBound.Y, WorldSpace.Y), math.min(MinBound.Z, WorldSpace.Z))
                MaxBound = Vector3.new(math.max(MaxBound.X, WorldSpace.X), math.max(MaxBound.Y, WorldSpace.Y), math.max(MaxBound.Z, WorldSpace.Z))
            end
        end
    end

    if MinBound == Vector3.new(math.huge, math.huge, math.huge) then return end
    local Center = (MinBound + MaxBound) / 2
    return CFrame.new(Center), MaxBound - MinBound + Increase, Center
end

Utility.Funcs.GetCase = function(Text, CaseType)
    CaseType = CaseType or "lowercase"

    if CaseType == "UPPERCASE" then
        return Text:upper()
    elseif CaseType == "lowercase" then
        return Text:lower()
    else
        return Text
    end
end

Utility.Funcs.MakeText = function(Parent)
    local Label = Instance.new("TextLabel")
    Label.Parent = Parent
    Label.Size = UDim2.new(0, 4, 0, 4)
    Label.BackgroundTransparency = 1
    Label.TextColor3 = Color3.fromRGB(255, 255, 255)
    Label.TextStrokeTransparency = 0
    Label.TextScaled = false
    Label.TextSize = 10
    Label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    Label.FontFace = Fonts[Config.Text.Font]
    Label.Text = ""
    return Label
end

Utility.Funcs.CreateBox = function(Parent, PlayerName)
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

    local Gradient = Instance.new("UIGradient")
    Gradient.Name = "Gradient"
    Gradient.Rotation = 45
    Gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255))
    })
    Gradient.Parent = Stroke

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

    return {
        Box = BoxContainer,
        Stroke = Stroke,
        Gradient = Gradient,
        Fill = FillFrame,
        FillGradient = FillGradient,
    }
end

Utility.Funcs.CreateHighlight = function(Player, Character)
    local Existing = Cache[Player] and Cache[Player].Highlight
    if Existing then
        Existing:Destroy()
    end

    local H = Instance.new("Highlight")
    H.FillColor = Config.Highlight.Color
    H.OutlineColor = Config.Highlight.Outline
    H.DepthMode = Config.Highlight.BehindWalls
        and Enum.HighlightDepthMode.AlwaysOnTop
        or Enum.HighlightDepthMode.Occluded
    H.Enabled = true
    H.Adornee = Character
    H.Parent = CoreGui

    if Cache[Player] then
        Cache[Player].Highlight = H
    end
end

Utility.Funcs.UpdateHighlight = function(Player, Character)
    local H = Cache[Player] and Cache[Player].Highlight
    if not H then return end
    H.Adornee = nil
    H.Parent = nil
    H.Adornee = Character
    H.Parent = CoreGui
end

Utility.Funcs.RemoveHighlight = function(Player)
    local H = Cache[Player] and Cache[Player].Highlight
    if H then
        H:Destroy()
        Cache[Player].Highlight = nil
    end
end

Utility.Funcs.CreateChams = function(Player, Character)
    Utility.Funcs.RemoveChams(Player)

    local ChamsList = {}
    local ZIndex = Config.Chams.BehindWalls and 1 or -1

    for _, Part in ipairs(GetBodyParts(Character)) do
        local Box = Instance.new("BoxHandleAdornment")
        Box.Visible = true
        Box.Adornee = Part
        Box.Color3 = Config.Chams.Color
        Box.ZIndex = ZIndex
        Box.AlwaysOnTop = Config.Chams.BehindWalls
        Box.Size = Part.Size + ChamsOffset
        Box.Archivable = true
        Box.Parent = CoreGui
        ChamsList[#ChamsList + 1] = Box
    end

    if Cache[Player] then
        Cache[Player].Chams = ChamsList
    end
end

Utility.Funcs.UpdateChams = function(Player, Character)
    Utility.Funcs.CreateChams(Player, Character)
end

Utility.Funcs.RemoveChams = function(Player)
    local ChamsList = Cache[Player] and Cache[Player].Chams
    if ChamsList then
        for I = 1, #ChamsList do
            ChamsList[I]:Destroy()
            ChamsList[I] = nil
        end
        Cache[Player].Chams = nil
    end
end

Utility.Funcs.ApplyMaterial = function(Player, Character)
    Character = Character or (Cache[Player] and Cache[Player].Character)
    if not Character then return end

    if not Player:HasAppearanceLoaded() then
        Player.CharacterAppearanceLoaded:Wait()
    end
    task.wait(0.2)

    local Mat = Config.Material.Material
    local Color = Config.Material.Color
    
    for _, Part in ipairs(GetBodyParts(Character)) do
        Part.Material = Mat
        Part.Color = Color
        if Part.Transparency ~= 1 then
            Part.Transparency = 0.5
        end
    end

    for _, Obj in ipairs(Character:GetDescendants()) do
        if Obj.ClassName == "Accessory" then
            local Handle = Obj:FindFirstChild("Handle")
            if Handle and Handle.ClassName == "MeshPart" then
                if not Handle:GetAttribute(MaterialAttribute) then
                    Handle:SetAttribute(MaterialAttribute, Handle.TextureID)
                end
                Handle.Material = Mat
                Handle.TextureID = ""
                Handle.Color = Color
            end
        end
    end

    local Shirt = Character:FindFirstChildOfClass("Shirt")
    if Shirt and Shirt.ShirtTemplate ~= "" then
        Shirt:SetAttribute("_OrigShirt", Shirt.ShirtTemplate)
        Shirt.ShirtTemplate = ""
    end

    local Pants = Character:FindFirstChildOfClass("Pants")
    if Pants and Pants.PantsTemplate ~= "" then
        Pants:SetAttribute("_OrigPants", Pants.PantsTemplate)
        Pants.PantsTemplate = ""
    end

    local ShirtGraphic = Character:FindFirstChildOfClass("ShirtGraphic")
    if ShirtGraphic and ShirtGraphic.Graphic ~= "" then
        ShirtGraphic:SetAttribute("_OrigGraphic", ShirtGraphic.Graphic)
        ShirtGraphic.Graphic = ""
    end
end

Utility.Funcs.RemoveMaterial = function(Player, Character)
    Character = Character or (Cache[Player] and Cache[Player].Character)
    if not Character then return end

    for _, Part in ipairs(GetBodyParts(Character)) do
        Part.Material = Enum.Material.SmoothPlastic
        if Part.Transparency ~= 1 then
            Part.Transparency = 0
        end
    end

    for _, Obj in ipairs(Character:GetDescendants()) do
        if Obj.ClassName == "Accessory" then
            local Handle = Obj:FindFirstChild("Handle")
            if Handle and Handle.ClassName == "MeshPart" then
                local Orig = Handle:GetAttribute(MaterialAttribute)
                if Orig then
                    Handle.TextureID = Orig
                    Handle:SetAttribute(MaterialAttribute, nil)
                end
                Handle.Material = Enum.Material.SmoothPlastic
                Handle.Transparency = 0
            end
        end
    end

    local Shirt = Character:FindFirstChildOfClass("Shirt")
    if Shirt then
        local Orig = Shirt:GetAttribute("_OrigShirt")
        if Orig then
            Shirt.ShirtTemplate = Orig
            Shirt:SetAttribute("_OrigShirt", nil)
        end
    end

    local Pants = Character:FindFirstChildOfClass("Pants")
    if Pants then
        local Orig = Pants:GetAttribute("_OrigPants")
        if Orig then
            Pants.PantsTemplate = Orig
            Pants:SetAttribute("_OrigPants", nil)
        end
    end

    local ShirtGraphic = Character:FindFirstChildOfClass("ShirtGraphic")
    if ShirtGraphic then
        local Orig = ShirtGraphic:GetAttribute("_OrigGraphic")
        if Orig then
            ShirtGraphic.Graphic = Orig
            ShirtGraphic:SetAttribute("_OrigGraphic", nil)
        end
    end
end

Utility.Funcs.Render =
    LPH_NO_VIRTUALIZE(
    function(Player)
        if not Player then return end

        Cache[Player] = Cache[Player] or {}
        Cache[Player].Box = {}
        Cache[Player].Bars = {}
        Cache[Player].Text = {}
        Cache[Player].Highlight = nil
        Cache[Player].Chams = nil
        Cache[Player].Character = Player.Character
        Cache[Player].MaterialConn = nil

        local BoxGui = Instance.new("ScreenGui")
        BoxGui.Name = Player.Name .. "_BoxESP"
        BoxGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        BoxGui.Parent = CoreGui

        Cache[Player].Box.Full = Utility.Funcs.CreateBox(BoxGui, Player.Name)

        local DistanceGui = Instance.new("ScreenGui")
        DistanceGui.Parent = CoreGui

        local NameGui = Instance.new("ScreenGui")
        NameGui.Parent = CoreGui

        local WeaponGui = Instance.new("ScreenGui")
        WeaponGui.Parent = CoreGui

        Cache[Player].Text.Distance = Utility.Funcs.MakeText(DistanceGui)
        Cache[Player].Text.Weapon = Utility.Funcs.MakeText(WeaponGui)
        Cache[Player].Text.Name = Utility.Funcs.MakeText(NameGui)

        local ArmorGui = Instance.new("ScreenGui")
        ArmorGui.Name = Player.Name .. "_ArmorBar"
        ArmorGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        ArmorGui.Parent = CoreGui

        local ArmorOutline = Instance.new("Frame")
        ArmorOutline.BackgroundColor3 = Color3.new(0, 0, 0)
        ArmorOutline.BorderSizePixel = 0
        ArmorOutline.Name = "Outline"
        ArmorOutline.Parent = ArmorGui

        local ArmorFill = Instance.new("Frame")
        ArmorFill.BackgroundTransparency = 0
        ArmorFill.BorderSizePixel = 0
        ArmorFill.Name = "Fill"
        ArmorFill.Parent = ArmorOutline

        local ArmorGradient = Instance.new("UIGradient", ArmorFill)
        ArmorGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.Bars.Armor.Color1),
            ColorSequenceKeypoint.new(0.5, Config.Bars.Armor.Color2),
            ColorSequenceKeypoint.new(1, Config.Bars.Armor.Color3)
        })
        ArmorGradient.Rotation = 90

        Cache[Player].Bars.Armor = {
            Gui = ArmorGui,
            Outline = ArmorOutline,
            Frame = ArmorFill,
            Gradient = ArmorGradient,
            Tick = tick(),
            Rotation = 90
        }

        local HealthGui = Instance.new("ScreenGui")
        HealthGui.Name = Player.Name .. "_HealthBar"
        HealthGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        HealthGui.Parent = CoreGui

        local HealthOutline = Instance.new("Frame")
        HealthOutline.BackgroundColor3 = Color3.new(0, 0, 0)
        HealthOutline.BorderSizePixel = 0
        HealthOutline.Name = "Outline"
        HealthOutline.Parent = HealthGui

        local HealthFill = Instance.new("Frame")
        HealthFill.BackgroundTransparency = 0
        HealthFill.BorderSizePixel = 0
        HealthFill.Name = "Fill"
        HealthFill.Parent = HealthOutline

        local HealthGradient = Instance.new("UIGradient", HealthFill)
        HealthGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Config.Bars.Health.Color1),
            ColorSequenceKeypoint.new(0.5, Config.Bars.Health.Color2),
            ColorSequenceKeypoint.new(1, Config.Bars.Health.Color3)
        })
        HealthGradient.Rotation = 90

        Cache[Player].Bars.Health = {
            Gui = HealthGui,
            Outline = HealthOutline,
            Frame = HealthFill,
            Gradient = HealthGradient,
            Tick = tick(),
            Rotation = 90
        }

        local Char = Player.Character
        if Char then
            if Config.Highlight.Enabled then
                Utility.Funcs.CreateHighlight(Player, Char)
            end
            if Config.Chams.Enabled then
                Utility.Funcs.CreateChams(Player, Char)
            end
            if Config.Material.Enabled then
                task.spawn(Utility.Funcs.ApplyMaterial, Player, Char)
            end
        end

        Player.CharacterAdded:Connect(function(NewChar)
            Cache[Player].Character = NewChar

            if Config.Highlight.Enabled then
                Utility.Funcs.UpdateHighlight(Player, NewChar)
            end
            if Config.Chams.Enabled then
                Utility.Funcs.UpdateChams(Player, NewChar)
            end
            if Config.Material.Enabled then
                task.spawn(Utility.Funcs.ApplyMaterial, Player, NewChar)
            end
        end)
    end
)

Utility.Funcs.ClearEsp =
    LPH_NO_VIRTUALIZE(
    function(Player)
        if not Cache[Player] then return end

        if Cache[Player].Box and Cache[Player].Box.Full then
            if Cache[Player].Box.Full.Box then
                Cache[Player].Box.Full.Box.Visible = false
            end
        end

        if Cache[Player].Text then
            if Cache[Player].Text.Distance then
                Cache[Player].Text.Distance.Visible = false
            end
            if Cache[Player].Text.Weapon then
                Cache[Player].Text.Weapon.Visible = false
            end
            if Cache[Player].Text.Name then
                Cache[Player].Text.Name.Visible = false
            end
        end

        if Cache[Player].Bars then
            if Cache[Player].Bars.Health and Cache[Player].Bars.Health.Frame then
                Cache[Player].Bars.Health.Frame.Visible = false
                Cache[Player].Bars.Health.Outline.Visible = false
            end

            if Cache[Player].Bars.Armor and Cache[Player].Bars.Armor.Frame then
                Cache[Player].Bars.Armor.Frame.Visible = false
                Cache[Player].Bars.Armor.Outline.Visible = false
            end
        end

        Utility.Funcs.RemoveHighlight(Player)
        Utility.Funcs.RemoveChams(Player)
    end
)

Utility.Funcs.Update =
    LPH_NO_VIRTUALIZE(
    function(Player)
        if not Player or not Cache[Player] then return end

        local Character = Player.Character
        local ClientCharacter = game.Players.LocalPlayer.Character
        local Camera = workspace.CurrentCamera

        if not Character or not ClientCharacter then return end

        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChildWhichIsA("Humanoid")
        if not RootPart or not Humanoid then
            Utility.Funcs.ClearEsp(Player)
            return
        end

        local CF, Size3D, Center = Utility.Funcs.CustomBounds(Character)
        if not CF then
            Utility.Funcs.ClearEsp(Player)
            return
        end

        local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Center)
        if not OnScreen then
            Utility.Funcs.ClearEsp(Player)
            return
        end

        local Distance = (Camera.CFrame.Position - Center).Magnitude
        local Height = math.tan(math.rad(Camera.FieldOfView / 2)) * 2 * Distance
        local Scale = Vector2.new((Camera.ViewportSize.Y / Height) * Size3D.X, (Camera.ViewportSize.Y / Height) * Size3D.Y)
        local Position = Vector2.new(ScreenPos.X - Scale.X / 2, ScreenPos.Y - Scale.Y / 2)

        local PlayerCache = Cache[Player]
        local FullBox = PlayerCache.Box.Full

        local Highlight = PlayerCache.Highlight
        if Config.Highlight.Enabled then
            if not Highlight then
                Utility.Funcs.CreateHighlight(Player, Character)
                Highlight = PlayerCache.Highlight
            end
            if Highlight then
                Highlight.FillColor = Config.Highlight.Color
                Highlight.OutlineColor = Config.Highlight.Outline
                Highlight.DepthMode = Config.Highlight.BehindWalls
                    and Enum.HighlightDepthMode.AlwaysOnTop
                    or Enum.HighlightDepthMode.Occluded
                Highlight.Enabled = true
            end
        elseif Highlight then
            Highlight.Enabled = false
        end

        local ChamsList = PlayerCache.Chams
        if Config.Chams.Enabled then
            if not ChamsList then
                Utility.Funcs.CreateChams(Player, Character)
                ChamsList = PlayerCache.Chams
            end
            if ChamsList then
                local Z = Config.Chams.BehindWalls and 1 or -1
                for I = 1, #ChamsList do
                    local C = ChamsList[I]
                    C.Color3 = Config.Chams.Color
                    C.ZIndex = Z
                    C.AlwaysOnTop = Config.Chams.BehindWalls
                end
            end
        elseif ChamsList then
            Utility.Funcs.RemoveChams(Player)
        end

        if Config.Box.Enabled and FullBox.Box then
            FullBox.Box.Visible = true
            FullBox.Box.Position = UDim2.new(0, Position.X, 0, Position.Y - GuiInset.Y)
            FullBox.Box.Size = UDim2.new(0, Scale.X, 0, Scale.Y)

            if FullBox.Stroke then
                FullBox.Stroke.Thickness = 2
            end

            if FullBox.Gradient then
                FullBox.Gradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Config.Box.Gradient.Color1),
                    ColorSequenceKeypoint.new(0.5, Config.Box.Gradient.Color2),
                    ColorSequenceKeypoint.new(1, Config.Box.Gradient.Color3)
                })
            end

            if Config.Box.Filled.Enabled and FullBox.Fill then
                FullBox.Fill.Visible = true

                if FullBox.FillGradient then
                    FullBox.FillGradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Config.Box.Filled.Gradient.Color1),
                        ColorSequenceKeypoint.new(0.5, Config.Box.Filled.Gradient.Color2),
                        ColorSequenceKeypoint.new(1, Config.Box.Filled.Gradient.Color3)
                    })

                    if Config.Box.Filled.Gradient.Rotation.Moving.Enabled then
                        local CurrentTick = tick()
                        local Delta = CurrentTick - LastTick
                        RotationAngle = RotationAngle + Delta * Config.Box.Filled.Gradient.Rotation.Moving.Speed
                        FullBox.FillGradient.Rotation = RotationAngle % 360
                        LastTick = CurrentTick
                    else
                        FullBox.FillGradient.Rotation = Config.Box.Filled.Gradient.Rotation.Amount
                    end
                end
            elseif FullBox.Fill then
                FullBox.Fill.Visible = false
            end
        elseif FullBox.Box then
            FullBox.Box.Visible = false
        end

        local BarHeight = Scale.Y
        local BarWidth = Config.Bars.Width
        local BaseX = Position.X
        local Y = Position.Y - GuiInset.Y

        local HealthBarVisible = false
        local ArmorBarVisible = false

        if Config.Bars.Health.Enabled and Humanoid then
            local TargetHealth = math.clamp(Humanoid.Health / Humanoid.MaxHealth, 0, 1)
            local LastHealth = PlayerCache.Bars.Health.LastHealth or TargetHealth
            local LerpedHealth = LastHealth + (TargetHealth - LastHealth) * Config.Bars.Lerp
            PlayerCache.Bars.Health.LastHealth = LerpedHealth

            local X = BaseX - (BarWidth + 4)
            local Outline = PlayerCache.Bars.Health.Outline
            local Fill = PlayerCache.Bars.Health.Frame

            if Outline and Fill then
                HealthBarVisible = true
                Outline.Visible = true

                if Config.Bars.Resize then
                    local CurrentBarHeight = math.max(BarHeight * LerpedHealth, 2)
                    Outline.Position = UDim2.new(0, X - 1, 0, Y + BarHeight - CurrentBarHeight - 1)
                    Outline.Size = UDim2.new(0, BarWidth + 2, 0, CurrentBarHeight + 2)
                    Fill.Visible = true
                    Fill.Position = UDim2.new(0, 1, 0, 1)
                    Fill.Size = UDim2.new(0, BarWidth, 0, CurrentBarHeight)
                else
                    Outline.Position = UDim2.new(0, X - 1, 0, Y - 1)
                    Outline.Size = UDim2.new(0, BarWidth + 2, 0, BarHeight + 2)
                    Fill.Visible = true
                    Fill.Position = UDim2.new(0, 1, 0, (1 - LerpedHealth) * BarHeight + 1)
                    Fill.Size = UDim2.new(0, BarWidth, 0, LerpedHealth * BarHeight)
                end

                Outline.BackgroundTransparency = 0.2

                if PlayerCache.Bars.Health.Gradient then
                    if Config.Bars.Type == "Gradient" then
                        PlayerCache.Bars.Health.Gradient.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, Config.Bars.Health.Color1),
                            ColorSequenceKeypoint.new(0.5, Config.Bars.Health.Color2),
                            ColorSequenceKeypoint.new(1, Config.Bars.Health.Color3)
                        })
                    elseif Config.Bars.Type == "Solid Color" then
                        PlayerCache.Bars.Health.Gradient.Color = ColorSequence.new(Config.Bars.Health.Color1)
                    end
                end
            end
        else
            if PlayerCache.Bars.Health.Outline then PlayerCache.Bars.Health.Outline.Visible = false end
            if PlayerCache.Bars.Health.Frame then PlayerCache.Bars.Health.Frame.Visible = false end
        end

        if Config.Bars.Armor.Enabled and Character then
            local BodyEffects = Character:FindFirstChild("BodyEffects")
            local Values = BodyEffects and BodyEffects:FindFirstChild("Armor")
            local ArmorValue = Values and Values.Value or 0
            local TargetArmor = math.clamp(ArmorValue / 130, 0, 1)

            local ShouldShowArmor = true
            if Config.Bars.Armor.Armored then
                ShouldShowArmor = ArmorValue > 0
            end

            if ShouldShowArmor then
                local LastArmor = PlayerCache.Bars.Armor.LastArmor or TargetArmor
                local LerpedArmor = LastArmor + (TargetArmor - LastArmor) * Config.Bars.Lerp
                PlayerCache.Bars.Armor.LastArmor = LerpedArmor

                local X
                if HealthBarVisible then
                    X = BaseX - (BarWidth * 2 + 6 + 2)
                else
                    X = BaseX - (BarWidth + 4)
                end

                local Outline = PlayerCache.Bars.Armor.Outline
                local Fill = PlayerCache.Bars.Armor.Frame

                if Outline and Fill then
                    ArmorBarVisible = true
                    Outline.Visible = true

                    if Config.Bars.Resize then
                        local CurrentBarHeight = math.max(BarHeight * LerpedArmor, 2)
                        Outline.Position = UDim2.new(0, X - 1, 0, Y + BarHeight - CurrentBarHeight - 1)
                        Outline.Size = UDim2.new(0, BarWidth + 2, 0, CurrentBarHeight + 2)
                        Fill.Visible = true
                        Fill.Position = UDim2.new(0, 1, 0, 1)
                        Fill.Size = UDim2.new(0, BarWidth, 0, CurrentBarHeight)
                    else
                        Outline.Position = UDim2.new(0, X - 1, 0, Y - 1)
                        Outline.Size = UDim2.new(0, BarWidth + 2, 0, BarHeight + 2)
                        Fill.Visible = true
                        Fill.Position = UDim2.new(0, 1, 0, (1 - LerpedArmor) * BarHeight + 1)
                        Fill.Size = UDim2.new(0, BarWidth, 0, LerpedArmor * BarHeight)
                    end

                    Outline.BackgroundTransparency = 0.2

                    if PlayerCache.Bars.Armor.Gradient then
                        if Config.Bars.Type == "Gradient" then
                            PlayerCache.Bars.Armor.Gradient.Color = ColorSequence.new({
                                ColorSequenceKeypoint.new(0, Config.Bars.Armor.Color1),
                                ColorSequenceKeypoint.new(0.5, Config.Bars.Armor.Color2),
                                ColorSequenceKeypoint.new(1, Config.Bars.Armor.Color3)
                            })
                        elseif Config.Bars.Type == "Solid Color" then
                            PlayerCache.Bars.Armor.Gradient.Color = ColorSequence.new(Config.Bars.Armor.Color1)
                        end
                    end
                end
            else
                if PlayerCache.Bars.Armor.Outline then PlayerCache.Bars.Armor.Outline.Visible = false end
                if PlayerCache.Bars.Armor.Frame then PlayerCache.Bars.Armor.Frame.Visible = false end
            end
        else
            if PlayerCache.Bars.Armor.Outline then PlayerCache.Bars.Armor.Outline.Visible = false end
            if PlayerCache.Bars.Armor.Frame then PlayerCache.Bars.Armor.Frame.Visible = false end
        end

        local NameLabel = PlayerCache.Text.Name
        local WeaponLabel = PlayerCache.Text.Weapon
        local DistanceLabel = PlayerCache.Text.Distance

        local TextOffset = 15
        local BaseXText = Position.X + (Scale.X / 2)
        local BaseY = Position.Y - GuiInset.Y

        if Config.Text.Name.Enabled then
            NameLabel.Visible = true
            NameLabel.Position = UDim2.new(0, BaseXText - (NameLabel.AbsoluteSize.X / 2), 0, BaseY - TextOffset + 6)
            NameLabel.TextColor3 = Config.Text.Name.Color
            NameLabel.FontFace = Fonts[Config.Text.Font]
            if Config.Text.Name.Type == "DisplayName" then
                NameLabel.Text = Utility.Funcs.GetCase(Player.DisplayName, Config.Text.Name.Casing)
            else
                NameLabel.Text = Utility.Funcs.GetCase(Player.Name, Config.Text.Name.Casing)
            end
        else
            NameLabel.Visible = false
        end

        local WeaponPos, DistancePos

        if Config.Text.Weapon.Enabled and Config.Text.Distance.Enabled then
            WeaponPos = BaseY + Scale.Y + 5
            DistancePos = BaseY + Scale.Y + 15
        elseif Config.Text.Weapon.Enabled and not Config.Text.Distance.Enabled then
            WeaponPos = BaseY + Scale.Y + 5
        elseif not Config.Text.Weapon.Enabled and Config.Text.Distance.Enabled then
            DistancePos = BaseY + Scale.Y + 5
        end

        if Config.Text.Weapon.Enabled then
            WeaponLabel.Visible = true
            WeaponLabel.Position = UDim2.new(0, BaseXText - (WeaponLabel.AbsoluteSize.X / 2), 0, WeaponPos)
            WeaponLabel.TextColor3 = Config.Text.Weapon.Color
            WeaponLabel.FontFace = Fonts[Config.Text.Font]
            local Tool = Player.Character:FindFirstChildOfClass("Tool")
            WeaponLabel.Text = Utility.Funcs.GetCase((Tool and Tool.Name) or "None", Config.Text.Weapon.Casing)
        else
            WeaponLabel.Visible = false
        end

        if Config.Text.Distance.Enabled then
            DistanceLabel.Visible = true
            DistanceLabel.Position = UDim2.new(0, BaseXText - (DistanceLabel.AbsoluteSize.X / 2), 0, DistancePos)
            DistanceLabel.TextColor3 = Config.Text.Distance.Color
            DistanceLabel.FontFace = Fonts[Config.Text.Font]
            DistanceLabel.Text = Utility.Funcs.GetCase(string.format("[%.0f]", Distance * 0.28), Config.Text.Distance.Casing)
        else
            DistanceLabel.Visible = false
        end
    end
)

for _, Player in ipairs(game:GetService("Players"):GetPlayers()) do
    if Player ~= game.Players.LocalPlayer then
        Utility.Funcs.Render(Player)
    end
end

game:GetService("Players").PlayerAdded:Connect(function(Player)
    if Player ~= game.Players.LocalPlayer then
        Utility.Funcs.Render(Player)
    end
end)

game:GetService("Players").PlayerRemoving:Connect(function(Player)
    if Player ~= game.Players.LocalPlayer then
        Utility.Funcs.ClearEsp(Player)
    end
end)

Connections.Main = Connections.Main or {}

Connections.Main.RenderStepped = game:GetService("RunService").Heartbeat:Connect(function()
    for V, _ in pairs(Cache) do
        if V then
            Utility.Funcs.Update(V)
        end
    end
end)

return Config
