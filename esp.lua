local ESP = {}

function ESP:Initialize(Tab)
    print("ESP module initializing...")

    if not getgenv().DeepESP then getgenv().DeepESP = {} end

    local Config = {
        Box = {
            Enabled = false,
            Color = Color3.fromRGB(255, 255, 255),
            UseGradient = false,
            Gradient = {
                Color1 = Color3.fromRGB(255, 255, 255),
                Color2 = Color3.fromRGB(255, 255, 255),
                Color3 = Color3.fromRGB(255, 255, 255),
            },
            Filled = {
                Enabled = false,
                Color = Color3.fromRGB(255, 255, 255),
                Gradient = {
                    Color1 = Color3.fromRGB(255, 255, 255),
                    Color2 = Color3.fromRGB(255, 255, 255),
                    Color3 = Color3.fromRGB(255, 255, 255),
                    Rotation = { Amount = 45, Moving = { Enabled = false, Speed = 300 } },
                },
            },
        },
        Text = {
            Font = "SourceSansBold",
            Name = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Type = "DisplayName", Casing = "lowercase" },
            Weapon = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Casing = "lowercase" },
            Distance = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Casing = "lowercase" },
        },
        Bars = {
            Resize = false, Width = 2.5, Lerp = 0.05, Type = "Gradient",
            Health = { Enabled = false, Color1 = Color3.fromRGB(0, 255, 0), Color2 = Color3.fromRGB(255, 255, 0), Color3 = Color3.fromRGB(255, 0, 0) },
            Armor = { Enabled = false, Color1 = Color3.fromRGB(0, 0, 255), Color2 = Color3.fromRGB(135, 206, 235), Color3 = Color3.fromRGB(1, 0, 0), Armored = false },
        },
        Highlight = { Enabled = false, BehindWalls = false, Color = Color3.fromRGB(255, 255, 255), Outline = Color3.fromRGB(0, 0, 0) },
        Chams = { Enabled = false, BehindWalls = false, Color = Color3.fromRGB(255, 255, 255) },
        Material = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.ForceField },
    }

    local Fonts = {
        SourceSans = Enum.Font.SourceSans,
        SourceSansBold = Enum.Font.SourceSansBold,
        Gotham = Enum.Font.Gotham,
        GothamBold = Enum.Font.GothamBold,
        Tahoma = Enum.Font.SourceSans,
        TahomaBold = Enum.Font.SourceSansBold,
        Minecraft = Enum.Font.Minecraft,
        Cartoon = Enum.Font.Cartoon,
    }

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local CoreGui = game:GetService("CoreGui")
    local GuiInset = game:GetService("GuiService"):GetGuiInset()

    local Cache = {}
    local Connections = {}
    local RotationAngle, LastTick = -45, tick()
    local Increase = Vector3.new(2, 2, 2)
    local ChamsOffset = Vector3.new(0.01, 0.01, 0.01)
    local MatAttr = ("ESP_Mat_%d"):format(math.random(10000, 99999))
    local Vertices = {
        { -0.5, -0.5, -0.5 }, { -0.5, 0.5, -0.5 }, { 0.5, -0.5, -0.5 }, { 0.5, 0.5, -0.5 },
        { -0.5, -0.5, 0.5 }, { -0.5, 0.5, 0.5 }, { 0.5, -0.5, 0.5 }, { 0.5, 0.5, 0.5 }
    }

    local function GetCase(text, ct)
        ct = ct or "lowercase"
        if ct == "UPPERCASE" then return text:upper() end
        if ct == "lowercase" then return text:lower() end
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
        local MinBound = Vector3.new(math.huge, math.huge, math.huge)
        local MaxBound = Vector3.new(-math.huge, -math.huge, -math.huge)
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

    local function CreateHighlight(Player, Character)
        if Cache[Player] and Cache[Player].Highlight then
            Cache[Player].Highlight:Destroy()
        end
        local H = Instance.new("Highlight")
        H.FillColor = Config.Highlight.Color
        H.OutlineColor = Config.Highlight.Outline
        H.DepthMode = Config.Highlight.BehindWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
        H.Enabled = true
        H.Adornee = Character
        H.Parent = CoreGui
        if Cache[Player] then Cache[Player].Highlight = H end
    end

    local function CreateChams(Player, Character)
        if Cache[Player] and Cache[Player].Chams then
            for _, c in ipairs(Cache[Player].Chams) do c:Destroy() end
        end
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
            Box.Parent = CoreGui
            ChamsList[#ChamsList + 1] = Box
        end
        if Cache[Player] then Cache[Player].Chams = ChamsList end
    end

    local function ApplyMaterial(Player, Character)
        if not Character then return end
        if not Player:HasAppearanceLoaded() then Player.CharacterAppearanceLoaded:Wait() end
        task.wait(0.2)
        local Mat = Config.Material.Material
        local Col = Config.Material.Color
        for _, Part in ipairs(GetBodyParts(Character)) do
            Part.Material = Mat
            Part.Color = Col
            if Part.Transparency ~= 1 then Part.Transparency = 0.5 end
        end
        for _, Obj in ipairs(Character:GetDescendants()) do
            if Obj.ClassName == "Accessory" then
                local Handle = Obj:FindFirstChild("Handle")
                if Handle and Handle:IsA("MeshPart") then
                    if not Handle:GetAttribute(MatAttr) then Handle:SetAttribute(MatAttr, Handle.TextureID) end
                    Handle.Material = Mat; Handle.TextureID = ""; Handle.Color = Col
                end
            end
        end
        local Shirt = Character:FindFirstChildOfClass("Shirt")
        if Shirt and Shirt.ShirtTemplate ~= "" then Shirt:SetAttribute("_OS", Shirt.ShirtTemplate); Shirt.ShirtTemplate = "" end
        local Pants = Character:FindFirstChildOfClass("Pants")
        if Pants and Pants.PantsTemplate ~= "" then Pants:SetAttribute("_OP", Pants.PantsTemplate); Pants.PantsTemplate = "" end
        local SG = Character:FindFirstChildOfClass("ShirtGraphic")
        if SG and SG.Graphic ~= "" then SG:SetAttribute("_OG", SG.Graphic); SG.Graphic = "" end
    end

    local function RevertMaterial(Player, Character)
        if not Character then return end
        for _, Part in ipairs(GetBodyParts(Character)) do
            Part.Material = Enum.Material.SmoothPlastic
            if Part.Transparency ~= 1 then Part.Transparency = 0 end
        end
        for _, Obj in ipairs(Character:GetDescendants()) do
            if Obj.ClassName == "Accessory" then
                local Handle = Obj:FindFirstChild("Handle")
                if Handle and Handle:IsA("MeshPart") then
                    local O = Handle:GetAttribute(MatAttr)
                    if O then Handle.TextureID = O; Handle:SetAttribute(MatAttr, nil) end
                    Handle.Material = Enum.Material.SmoothPlastic; Handle.Transparency = 0
                end
            end
        end
        local Shirt = Character:FindFirstChildOfClass("Shirt")
        if Shirt then local O = Shirt:GetAttribute("_OS"); if O then Shirt.ShirtTemplate = O; Shirt:SetAttribute("_OS", nil) end end
        local Pants = Character:FindFirstChildOfClass("Pants")
        if Pants then local O = Pants:GetAttribute("_OP"); if O then Pants.PantsTemplate = O; Pants:SetAttribute("_OP", nil) end end
        local SG = Character:FindFirstChildOfClass("ShirtGraphic")
        if SG then local O = SG:GetAttribute("_OG"); if O then SG.Graphic = O; SG:SetAttribute("_OG", nil) end end
    end

    local function MakeBar(Player, Name)
        local cfg = Name == "Health" and Config.Bars.Health or Config.Bars.Armor
        local Gui = Instance.new("ScreenGui")
        Gui.Name = Player.Name .. "_" .. Name .. "Bar"
        Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        Gui.Parent = CoreGui
        local Outline = Instance.new("Frame")
        Outline.BackgroundColor3 = Color3.new(0, 0, 0)
        Outline.BorderSizePixel = 0
        Outline.Parent = Gui
        local Fill = Instance.new("Frame")
        Fill.BackgroundTransparency = 0
        Fill.BorderSizePixel = 0
        Fill.Parent = Outline
        local Grad = Instance.new("UIGradient")
        Grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, cfg.Color1), ColorSequenceKeypoint.new(0.5, cfg.Color2), ColorSequenceKeypoint.new(1, cfg.Color3),
        })
        Grad.Rotation = 90
        Grad.Parent = Fill
        return { Gui = Gui, Outline = Outline, Frame = Fill, Gradient = Grad }
    end

    local function Render(Player)
        if not Player then return end
        if Player == LocalPlayer then return end

        Cache[Player] = Cache[Player] or {}
        Cache[Player].Box = Cache[Player].Box or {}
        Cache[Player].Text = Cache[Player].Text or {}
        Cache[Player].Bars = Cache[Player].Bars or {}
        Cache[Player].Highlight = Cache[Player].Highlight
        Cache[Player].Chams = Cache[Player].Chams
        Cache[Player].Character = Player.Character
        Cache[Player].MatDone = Cache[Player].MatDone or false

        if not Cache[Player].Box.Box then
            local BoxGui = Instance.new("ScreenGui")
            BoxGui.Name = Player.Name .. "_BoxESP"
            BoxGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            BoxGui.Parent = CoreGui

            local BoxContainer = Instance.new("Frame")
            BoxContainer.Name = "BoxContainer"
            BoxContainer.BackgroundTransparency = 1
            BoxContainer.Size = UDim2.new(0, 0, 0, 0)
            BoxContainer.Parent = BoxGui

            local BoxFrame = Instance.new("Frame")
            BoxFrame.BackgroundTransparency = 1
            BoxFrame.Size = UDim2.new(1, 0, 1, 0)
            BoxFrame.Parent = BoxContainer

            local Stroke = Instance.new("UIStroke")
            Stroke.Thickness = 2
            Stroke.Color = Config.Box.Color
            Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            Stroke.Parent = BoxFrame

            local Gradient = Instance.new("UIGradient")
            Gradient.Rotation = 45
            Gradient.Enabled = Config.Box.UseGradient
            Gradient.Parent = Stroke

            local FillFrame = Instance.new("Frame")
            FillFrame.BackgroundColor3 = Config.Box.Filled.Color
            FillFrame.BackgroundTransparency = 0.5
            FillFrame.Size = UDim2.new(1, 0, 1, 0)
            FillFrame.Visible = false
            FillFrame.Parent = BoxContainer

            local FillGradient = Instance.new("UIGradient")
            FillGradient.Rotation = 45
            FillGradient.Parent = FillFrame

            Cache[Player].Box = {
                Box = BoxContainer, Stroke = Stroke, Gradient = Gradient,
                Fill = FillFrame, FillGradient = FillGradient, Gui = BoxGui
            }
        end

        if not Cache[Player].Text.Name then
            local NameGui = Instance.new("ScreenGui"); NameGui.Parent = CoreGui
            local NameLabel = Instance.new("TextLabel")
            NameLabel.BackgroundTransparency = 1; NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            NameLabel.TextStrokeTransparency = 0; NameLabel.TextSize = 10; NameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            NameLabel.Parent = NameGui
            Cache[Player].Text.Name = NameLabel
        end

        if not Cache[Player].Text.Weapon then
            local WGui = Instance.new("ScreenGui"); WGui.Parent = CoreGui
            local WLabel = Instance.new("TextLabel")
            WLabel.BackgroundTransparency = 1; WLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            WLabel.TextStrokeTransparency = 0; WLabel.TextSize = 10; WLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            WLabel.Parent = WGui
            Cache[Player].Text.Weapon = WLabel
        end

        if not Cache[Player].Text.Distance then
            local DGui = Instance.new("ScreenGui"); DGui.Parent = CoreGui
            local DLabel = Instance.new("TextLabel")
            DLabel.BackgroundTransparency = 1; DLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            DLabel.TextStrokeTransparency = 0; DLabel.TextSize = 10; DLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
            DLabel.Parent = DGui
            Cache[Player].Text.Distance = DLabel
        end

        if not Cache[Player].Bars.Health then
            Cache[Player].Bars.Health = MakeBar(Player, "Health")
        end
        if not Cache[Player].Bars.Armor then
            Cache[Player].Bars.Armor = MakeBar(Player, "Armor")
        end

        local Char = Player.Character
        if Char then
            if Config.Highlight.Enabled then CreateHighlight(Player, Char) end
            if Config.Chams.Enabled then CreateChams(Player, Char) end
            if Config.Material.Enabled and not Cache[Player].MatDone then
                task.spawn(ApplyMaterial, Player, Char); Cache[Player].MatDone = true
            end
        end

        if not Cache[Player].CharConn then
            Cache[Player].CharConn = Player.CharacterAdded:Connect(function(nc)
                Cache[Player].Character = nc
                if Config.Highlight.Enabled then CreateHighlight(Player, nc) end
                if Config.Chams.Enabled then CreateChams(Player, nc) end
                if Config.Material.Enabled and not Cache[Player].MatDone then
                    task.spawn(ApplyMaterial, Player, nc); Cache[Player].MatDone = true
                end
            end)
        end
    end

    local function ClearESP(Player)
        if not Cache[Player] then return end
        local c = Cache[Player]
        if c.Box and c.Box.Box then c.Box.Box:Destroy() end
        if c.Box and c.Box.Gui then c.Box.Gui:Destroy() end
        if c.Text then
            if c.Text.Name then c.Text.Name.Parent:Destroy() end
            if c.Text.Weapon then c.Text.Weapon.Parent:Destroy() end
            if c.Text.Distance then c.Text.Distance.Parent:Destroy() end
        end
        if c.Bars then
            if c.Bars.Health then c.Bars.Health.Gui:Destroy() end
            if c.Bars.Armor then c.Bars.Armor.Gui:Destroy() end
        end
        if c.Highlight then c.Highlight:Destroy() end
        if c.Chams then for _, ch in ipairs(c.Chams) do ch:Destroy() end end
        if c.CharConn then pcall(c.CharConn.Disconnect, c.CharConn) end
        Cache[Player] = nil
    end

    local function HidePlayer(Player)
        local c = Cache[Player]
        if not c then return end
        if c.Box and c.Box.Box then c.Box.Box.Visible = false end
        if c.Text then
            if c.Text.Name then c.Text.Name.Visible = false end
            if c.Text.Weapon then c.Text.Weapon.Visible = false end
            if c.Text.Distance then c.Text.Distance.Visible = false end
        end
        if c.Bars then
            if c.Bars.Health then c.Bars.Health.Outline.Visible = false; c.Bars.Health.Frame.Visible = false end
            if c.Bars.Armor then c.Bars.Armor.Outline.Visible = false; c.Bars.Armor.Frame.Visible = false end
        end
    end

    local function Update(Player)
        if not Player or not Cache[Player] then return end
        local c = Cache[Player]
        local Character = Player.Character
        local ClientCharacter = LocalPlayer.Character
        if not Character or not ClientCharacter then return end

        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not RootPart or not Humanoid then return end

        local CF, Size3D, Center = CustomBounds(Character)
        if not CF then return end

        local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Center)
        if not OnScreen then HidePlayer(Player); return end

        local Distance = (Camera.CFrame.Position - Center).Magnitude
        local Height = math.tan(math.rad(Camera.FieldOfView / 2)) * 2 * Distance
        local Scale = Vector2.new((Camera.ViewportSize.Y / Height) * Size3D.X, (Camera.ViewportSize.Y / Height) * Size3D.Y)
        local Position = Vector2.new(ScreenPos.X - Scale.X / 2, ScreenPos.Y - Scale.Y / 2)
        local InsetY = GuiInset.Y

        local now = tick()
        local dt = now - LastTick
        LastTick = now

        -- Highlight
        if Config.Highlight.Enabled then
            if not c.Highlight then CreateHighlight(Player, Character) end
            if c.Highlight then
                c.Highlight.FillColor = Config.Highlight.Color
                c.Highlight.OutlineColor = Config.Highlight.Outline
                c.Highlight.DepthMode = Config.Highlight.BehindWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            end
        elseif c.Highlight then
            c.Highlight:Destroy(); c.Highlight = nil
        end

        -- Chams
        if Config.Chams.Enabled then
            if not c.Chams then CreateChams(Player, Character) end
            local Z = Config.Chams.BehindWalls and 1 or -1
            for _, ch in ipairs(c.Chams or {}) do
                ch.Color3 = Config.Chams.Color; ch.ZIndex = Z; ch.AlwaysOnTop = Config.Chams.BehindWalls
            end
        elseif c.Chams then
            for _, ch in ipairs(c.Chams) do ch:Destroy() end; c.Chams = nil
        end

        -- Material
        if Config.Material.Enabled and not c.MatDone then
            task.spawn(ApplyMaterial, Player, Character); c.MatDone = true
        elseif not Config.Material.Enabled and c.MatDone then
            RevertMaterial(Player, Character); c.MatDone = false
        end

        -- Box
        if Config.Box.Enabled and c.Box.Box then
            c.Box.Box.Visible = true
            c.Box.Box.Position = UDim2.new(0, Position.X, 0, Position.Y - InsetY)
            c.Box.Box.Size = UDim2.new(0, Scale.X, 0, Scale.Y)
            c.Box.Stroke.Color = Config.Box.Color
            c.Box.Gradient.Enabled = Config.Box.UseGradient
            if Config.Box.UseGradient then
                c.Box.Gradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Config.Box.Gradient.Color1),
                    ColorSequenceKeypoint.new(0.5, Config.Box.Gradient.Color2),
                    ColorSequenceKeypoint.new(1, Config.Box.Gradient.Color3),
                })
            end
            if Config.Box.Filled.Enabled then
                c.Box.Fill.Visible = true
                c.Box.Fill.BackgroundColor3 = Config.Box.Filled.Color
                c.Box.FillGradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Config.Box.Filled.Gradient.Color1),
                    ColorSequenceKeypoint.new(0.5, Config.Box.Filled.Gradient.Color2),
                    ColorSequenceKeypoint.new(1, Config.Box.Filled.Gradient.Color3),
                })
                if Config.Box.Filled.Gradient.Rotation.Moving.Enabled then
                    RotationAngle = (RotationAngle + dt * Config.Box.Filled.Gradient.Rotation.Moving.Speed) % 360
                    c.Box.FillGradient.Rotation = RotationAngle
                else
                    c.Box.FillGradient.Rotation = Config.Box.Filled.Gradient.Rotation.Amount
                end
            else
                c.Box.Fill.Visible = false
            end
        elseif c.Box.Box then
            c.Box.Box.Visible = false
        end

        -- Bars
        local function DrawBar(bar, bcfg, val, maxVal, lastKey, offX)
            if not bar then return false end
            if bcfg.Enabled then
                local pct = math.clamp(val / maxVal, 0, 1)
                local lerp = c[lastKey] or pct
                lerp = lerp + (pct - lerp) * Config.Bars.Lerp
                c[lastKey] = lerp
                local bw = Config.Bars.Width
                local bh = Scale.Y
                local x = Position.X - (bw + 4) - offX
                local out = bar.Outline; local fill = bar.Frame
                out.Visible = true
                if Config.Bars.Resize then
                    local ch = math.max(bh * lerp, 2)
                    out.Position = UDim2.new(0, x - 1, 0, Position.Y - InsetY + bh - ch - 1)
                    out.Size = UDim2.new(0, bw + 2, 0, ch + 2)
                    fill.Visible = true; fill.Position = UDim2.new(0, 1, 0, 1); fill.Size = UDim2.new(0, bw, 0, ch)
                else
                    out.Position = UDim2.new(0, x - 1, 0, Position.Y - InsetY - 1)
                    out.Size = UDim2.new(0, bw + 2, 0, bh + 2)
                    fill.Visible = true
                    fill.Position = UDim2.new(0, 1, 0, (1 - lerp) * bh + 1)
                    fill.Size = UDim2.new(0, bw, 0, lerp * bh)
                end
                out.BackgroundTransparency = 0.2
                bar.Gradient.Color = Config.Bars.Type == "Gradient"
                    and ColorSequence.new({ ColorSequenceKeypoint.new(0, bcfg.Color1), ColorSequenceKeypoint.new(0.5, bcfg.Color2), ColorSequenceKeypoint.new(1, bcfg.Color3) })
                    or ColorSequence.new(bcfg.Color1)
                return true
            else
                out.Visible = false; fill.Visible = false; return false
            end
        end

        local hpVis = DrawBar(c.Bars.Health, Config.Bars.Health, Humanoid.Health, Humanoid.MaxHealth, "HpLast", 0)
        if Config.Bars.Armor.Enabled then
            local be = Character:FindFirstChild("BodyEffects")
            local av = be and be:FindFirstChild("Armor")
            local val = av and av.Value or 0
            if Config.Bars.Armor.Armored and val <= 0 then
                c.Bars.Armor.Outline.Visible = false; c.Bars.Armor.Frame.Visible = false
            else
                DrawBar(c.Bars.Armor, Config.Bars.Armor, val, 130, "ArmLast", hpVis and (Config.Bars.Width * 2 + 6 + 2) or 0)
            end
        else
            c.Bars.Armor.Outline.Visible = false; c.Bars.Armor.Frame.Visible = false
        end

        -- Text
        local font = Fonts[Config.Text.Font] or Fonts.SourceSansBold
        local cx = Position.X + Scale.X / 2
        local cy = Position.Y - InsetY

        if Config.Text.Name.Enabled and c.Text.Name then
            local lbl = c.Text.Name
            lbl.Visible = true
            lbl.FontFace = font
            lbl.TextColor3 = Config.Text.Name.Color
            lbl.Text = GetCase(Config.Text.Name.Type == "DisplayName" and Player.DisplayName or Player.Name, Config.Text.Name.Casing)
            lbl.Position = UDim2.new(0, cx - lbl.AbsoluteSize.X / 2, 0, cy - 15)
        elseif c.Text.Name then
            c.Text.Name.Visible = false
        end

        if Config.Text.Weapon.Enabled and c.Text.Weapon then
            local lbl = c.Text.Weapon
            local tool = Character:FindFirstChildOfClass("Tool")
            lbl.Visible = true
            lbl.FontFace = font
            lbl.TextColor3 = Config.Text.Weapon.Color
            lbl.Text = GetCase(tool and tool.Name or "None", Config.Text.Weapon.Casing)
            lbl.Position = UDim2.new(0, cx - lbl.AbsoluteSize.X / 2, 0, cy + Scale.Y + 5 - InsetY)
        elseif c.Text.Weapon then
            c.Text.Weapon.Visible = false
        end

        if Config.Text.Distance.Enabled and c.Text.Distance then
            local lbl = c.Text.Distance
            lbl.Visible = true
            lbl.FontFace = font
            lbl.TextColor3 = Config.Text.Distance.Color
            lbl.Text = string.format("[%.0f]", Distance * 0.28)
            lbl.Position = UDim2.new(0, cx - lbl.AbsoluteSize.X / 2, 0, cy + Scale.Y + (Config.Text.Weapon.Enabled and 15 or 5) - InsetY)
        elseif c.Text.Distance then
            c.Text.Distance.Visible = false
        end
    end

    -- Connections
    local Heartbeat
    local function StartESP()
        for _, Player in ipairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer then Render(Player) end
        end
        Connections.PlayerAdded = Players.PlayerAdded:Connect(function(Player)
            if Player ~= LocalPlayer then Render(Player) end
        end)
        Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(Player)
            ClearESP(Player)
        end)
        Heartbeat = RunService.Heartbeat:Connect(function()
            for Player, _ in pairs(Cache) do
                if Player then Update(Player) end
            end
        end)
    end

    local function StopESP()
        if Heartbeat then Heartbeat:Disconnect(); Heartbeat = nil end
        for _, c in pairs(Connections) do if c then pcall(c.Disconnect, c) end end
        Connections = {}
        for Player, _ in pairs(Cache) do ClearESP(Player) end
    end

    -- UI
    local BoxGroup = Tab:AddLeftGroupbox("Box ESP")
    local TextGroup = Tab:AddRightGroupbox("Text ESP")
    local BarsGroup = Tab:AddRightGroupbox("Bars")
    local ExtraGroup = Tab:AddLeftGroupbox("Extra")

    BoxGroup:AddToggle("BoxEnabled", { Text = "Box ESP", Default = false, Callback = function(v) Config.Box.Enabled = v end })
    BoxGroup:AddColorPicker("BoxColor", { Default = Config.Box.Color, Title = "Box Color", Callback = function(v) Config.Box.Color = v end })
    BoxGroup:AddToggle("BoxGrad", { Text = "Box Gradient", Default = false, Callback = function(v) Config.Box.UseGradient = v end })
    BoxGroup:AddColorPicker("BoxCol1", { Default = Config.Box.Gradient.Color1, Title = "G1", Callback = function(v) Config.Box.Gradient.Color1 = v end })
    BoxGroup:AddColorPicker("BoxCol2", { Default = Config.Box.Gradient.Color2, Title = "G2", Callback = function(v) Config.Box.Gradient.Color2 = v end })
    BoxGroup:AddColorPicker("BoxCol3", { Default = Config.Box.Gradient.Color3, Title = "G3", Callback = function(v) Config.Box.Gradient.Color3 = v end })
    BoxGroup:AddToggle("BoxFilled", { Text = "Filled Box", Default = false, Callback = function(v) Config.Box.Filled.Enabled = v end })
    BoxGroup:AddColorPicker("FillColor", { Default = Config.Box.Filled.Color, Title = "Fill Color", Callback = function(v) Config.Box.Filled.Color = v end })
    BoxGroup:AddColorPicker("FillCol1", { Default = Config.Box.Filled.Gradient.Color1, Title = "F1", Callback = function(v) Config.Box.Filled.Gradient.Color1 = v end })
    BoxGroup:AddColorPicker("FillCol2", { Default = Config.Box.Filled.Gradient.Color2, Title = "F2", Callback = function(v) Config.Box.Filled.Gradient.Color2 = v end })
    BoxGroup:AddColorPicker("FillCol3", { Default = Config.Box.Filled.Gradient.Color3, Title = "F3", Callback = function(v) Config.Box.Filled.Gradient.Color3 = v end })
    BoxGroup:AddSlider("FillRot", { Text = "Fill Rotation", Default = 45, Min = 0, Max = 360, Rounding = 0, Callback = function(v) Config.Box.Filled.Gradient.Rotation.Amount = v end })
    BoxGroup:AddToggle("FillMove", { Text = "Animate Rotation", Default = false, Callback = function(v) Config.Box.Filled.Gradient.Rotation.Moving.Enabled = v end })
    BoxGroup:AddSlider("FillSpeed", { Text = "Speed", Default = 300, Min = 10, Max = 1000, Rounding = 0, Callback = function(v) Config.Box.Filled.Gradient.Rotation.Moving.Speed = v end })

    TextGroup:AddToggle("NameEnabled", { Text = "Name", Default = false, Callback = function(v) Config.Text.Name.Enabled = v end })
    TextGroup:AddColorPicker("NameColor", { Default = Config.Text.Name.Color, Callback = function(v) Config.Text.Name.Color = v end })
    TextGroup:AddDropdown("NameCasing", { Values = { "lowercase", "UPPERCASE", "Normal" }, Default = "lowercase", Text = "Casing", Callback = function(v) Config.Text.Name.Casing = v end })
    TextGroup:AddToggle("WeaponEnabled", { Text = "Weapon", Default = false, Callback = function(v) Config.Text.Weapon.Enabled = v end })
    TextGroup:AddColorPicker("WeaponColor", { Default = Config.Text.Weapon.Color, Callback = function(v) Config.Text.Weapon.Color = v end })
    TextGroup:AddToggle("DistanceEnabled", { Text = "Distance", Default = false, Callback = function(v) Config.Text.Distance.Enabled = v end })
    TextGroup:AddColorPicker("DistanceColor", { Default = Config.Text.Distance.Color, Callback = function(v) Config.Text.Distance.Color = v end })
    TextGroup:AddDropdown("ESPFont", { Values = { "SourceSans", "SourceSansBold", "Gotham", "GothamBold", "Minecraft", "Cartoon" }, Default = "SourceSansBold", Text = "Font", Callback = function(v) Config.Text.Font = v end })

    BarsGroup:AddToggle("HealthBar", { Text = "Health Bar", Default = false, Callback = function(v) Config.Bars.Health.Enabled = v end })
    BarsGroup:AddColorPicker("Hp1", { Default = Config.Bars.Health.Color1, Callback = function(v) Config.Bars.Health.Color1 = v end })
    BarsGroup:AddColorPicker("Hp2", { Default = Config.Bars.Health.Color2, Callback = function(v) Config.Bars.Health.Color2 = v end })
    BarsGroup:AddColorPicker("Hp3", { Default = Config.Bars.Health.Color3, Callback = function(v) Config.Bars.Health.Color3 = v end })
    BarsGroup:AddToggle("ArmorBar", { Text = "Armor Bar", Default = false, Callback = function(v) Config.Bars.Armor.Enabled = v end })
    BarsGroup:AddColorPicker("Ar1", { Default = Config.Bars.Armor.Color1, Callback = function(v) Config.Bars.Armor.Color1 = v end })
    BarsGroup:AddColorPicker("Ar2", { Default = Config.Bars.Armor.Color2, Callback = function(v) Config.Bars.Armor.Color2 = v end })
    BarsGroup:AddColorPicker("Ar3", { Default = Config.Bars.Armor.Color3, Callback = function(v) Config.Bars.Armor.Color3 = v end })
    BarsGroup:AddToggle("ArmOnly", { Text = "Show When Armored", Default = false, Callback = function(v) Config.Bars.Armor.Armored = v end })
    BarsGroup:AddSlider("BarW", { Text = "Bar Width", Default = 2.5, Min = 1, Max = 6, Rounding = 1, Callback = function(v) Config.Bars.Width = v end })
    BarsGroup:AddSlider("BarLerp", { Text = "Bar Smoothing", Default = 0.05, Min = 0.01, Max = 1, Rounding = 2, Callback = function(v) Config.Bars.Lerp = v end })
    BarsGroup:AddToggle("BarResize", { Text = "Resize Bars", Default = false, Callback = function(v) Config.Bars.Resize = v end })
    BarsGroup:AddDropdown("BarType", { Values = { "Gradient", "Solid Color" }, Default = "Gradient", Text = "Bar Style", Callback = function(v) Config.Bars.Type = v end })

    ExtraGroup:AddToggle("HighlightEnabled", { Text = "Highlight", Default = false, Callback = function(v) Config.Highlight.Enabled = v end })
    ExtraGroup:AddColorPicker("HLColor", { Default = Config.Highlight.Color, Callback = function(v) Config.Highlight.Color = v end })
    ExtraGroup:AddColorPicker("HLOutline", { Default = Config.Highlight.Outline, Callback = function(v) Config.Highlight.Outline = v end })
    ExtraGroup:AddToggle("HLWalls", { Text = "Behind Walls", Default = false, Callback = function(v) Config.Highlight.BehindWalls = v end })
    ExtraGroup:AddToggle("ChamsEnabled", { Text = "Chams", Default = false, Callback = function(v) Config.Chams.Enabled = v end })
    ExtraGroup:AddColorPicker("ChamsColor", { Default = Config.Chams.Color, Callback = function(v) Config.Chams.Color = v end })
    ExtraGroup:AddToggle("ChamsWalls", { Text = "Behind Walls", Default = false, Callback = function(v) Config.Chams.BehindWalls = v end })
    ExtraGroup:AddToggle("MatEnabled", { Text = "Material", Default = false, Callback = function(v) Config.Material.Enabled = v end })
    ExtraGroup:AddColorPicker("MatColor", { Default = Config.Material.Color, Callback = function(v) Config.Material.Color = v end })
    ExtraGroup:AddDropdown("MatType", { Values = { "ForceField", "Neon", "Glass", "SmoothPlastic" }, Default = "ForceField", Text = "Material", Callback = function(v) Config.Material.Material = Enum.Material[v] end })

    StartESP()
    print("ESP module loaded!")

    return {
        Cleanup = function()
            StopESP()
            print("ESP cleanup!")
        end
    }
end

return ESP