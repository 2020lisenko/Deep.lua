local ESP = {}
ESP.__index = ESP

function ESP:Initialize(Tab)
    local self = setmetatable({}, ESP)

    self.Enabled      = false
    self.Cache        = {}
    self.Connections  = {}
    self.FrameTick    = tick()
    self.RotationAngle = -45

    self.Config = {
        Box = {
            Enabled = false,
            Gradient = {
                Color1 = Color3.fromRGB(255, 255, 255),
                Color2 = Color3.fromRGB(255, 255, 255),
                Color3 = Color3.fromRGB(255, 255, 255),
            },
            Filled = {
                Enabled = false,
                Gradient = {
                    Color1 = Color3.fromRGB(255, 255, 255),
                    Color2 = Color3.fromRGB(255, 255, 255),
                    Color3 = Color3.fromRGB(255, 255, 255),
                    Rotation = {
                        Amount = 45,
                        Moving = { Enabled = false, Speed = 300 },
                    },
                },
            },
        },
        Text = {
            Font     = "GothamBold",
            Size     = 10,
            Name     = { Enabled = false, Color = Color3.fromRGB(255,255,255), Type = "DisplayName", Casing = "lowercase" },
            Weapon   = { Enabled = false, Color = Color3.fromRGB(255,255,255), Casing = "lowercase" },
            Distance = { Enabled = false, Color = Color3.fromRGB(255,255,255), Casing = "lowercase" },
        },
        Bars = {
            Resize = false,
            Width  = 2.5,
            Lerp   = 0.05,
            Type   = "Gradient",
            Health = {
                Enabled = false,
                Color1  = Color3.fromRGB(0, 255, 0),
                Color2  = Color3.fromRGB(255, 255, 0),
                Color3  = Color3.fromRGB(255, 0, 0),
            },
            Armor = {
                Enabled = false,
                Color1  = Color3.fromRGB(0, 0, 255),
                Color2  = Color3.fromRGB(135, 206, 235),
                Color3  = Color3.fromRGB(0, 100, 255),
                Armored = false,
            },
        },
        Material  = { Enabled = false, Color = Color3.fromRGB(255,255,255), Material = Enum.Material.ForceField },
        Highlight = { Enabled = false, BehindWalls = false, Color = Color3.fromRGB(255,255,255), Outline = Color3.fromRGB(0,0,0) },
        Chams     = { Enabled = false, BehindWalls = false, Color = Color3.fromRGB(255,255,255) },
    }

    self.Services = {
        Players    = game:GetService("Players"),
        RunService = game:GetService("RunService"),
        CoreGui    = game:GetService("CoreGui"),
        GuiService = game:GetService("GuiService"),
    }

    self:SetupConnections()
    self:CreateUI(Tab)

    return self
end

-- ─────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────

local Vertices = {
    {-0.5,-0.5,-0.5},{-0.5,0.5,-0.5},{0.5,-0.5,-0.5},{0.5,0.5,-0.5},
    {-0.5,-0.5,0.5},{-0.5,0.5,0.5},{0.5,-0.5,0.5},{0.5,0.5,0.5},
}
local Increase    = Vector3.new(2, 2, 2)
local ChamsOffset = Vector3.new(0.01, 0.01, 0.01)
local MatAttr     = ("ESP_Mat_%d"):format(math.random(10000, 99999))

local Fonts = {
    SourceSans     = Enum.Font.SourceSans,
    SourceSansBold = Enum.Font.SourceSansBold,
    Gotham         = Enum.Font.Gotham,
    GothamBold     = Enum.Font.GothamBold,
    Minecraft      = Enum.Font.Arcade, -- Исправлено: Enum.Font.Minecraft не существует в Roblox
    Cartoon        = Enum.Font.Cartoon,
}

local function SafeDestroy(obj)
    if obj and obj.Parent then
        pcall(function() obj:Destroy() end)
    end
end

local function GetBodyParts(char)
    local parts = {}
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("BasePart") and c.Name ~= "HumanoidRootPart" then
            parts[#parts + 1] = c
        end
    end
    return parts
end

local function CustomBounds(char)
    local mn = Vector3.new( math.huge,  math.huge,  math.huge)
    local mx = Vector3.new(-math.huge, -math.huge, -math.huge)
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") then
            local cf, sz = p.CFrame, p.Size
            for _, v in ipairs(Vertices) do
                local ws = cf:PointToWorldSpace(Vector3.new(
                    v[1] * sz.X,
                    (v[2] + 0.2) * (sz.Y + 0.2),
                    v[3] * sz.Z
                ))
                mn = Vector3.new(math.min(mn.X,ws.X), math.min(mn.Y,ws.Y), math.min(mn.Z,ws.Z))
                mx = Vector3.new(math.max(mx.X,ws.X), math.max(mx.Y,ws.Y), math.max(mx.Z,ws.Z))
            end
        end
    end
    if mn.X == math.huge then return nil, nil, nil end
    local center = (mn + mx) / 2
    return CFrame.new(center), mx - mn + Increase, center
end

local function GetCase(text, ct)
    if ct == "UPPERCASE" then return text:upper() end
    if ct == "lowercase"  then return text:lower() end
    return text
end

-- ─────────────────────────────────────────────────────────────
-- Cache management
-- ─────────────────────────────────────────────────────────────

function ESP:DeletePlayer(plr)
    local c = self.Cache[plr]
    if not c then return end
    SafeDestroy(c.BoxGui)
    SafeDestroy(c.NameGui)
    SafeDestroy(c.DistGui)
    SafeDestroy(c.WeapGui)
    if c.HpBar  then SafeDestroy(c.HpBar.Gui)  end
    if c.ArmBar then SafeDestroy(c.ArmBar.Gui) end
    SafeDestroy(c.Highlight)
    if c.Chams then
        for _, v in ipairs(c.Chams) do SafeDestroy(v) end
    end
    if c.CharConn then pcall(function() c.CharConn:Disconnect() end) end
    self.Cache[plr] = nil
end

function ESP:Clear()
    for p in pairs(self.Cache) do self:DeletePlayer(p) end
    self.Cache = {}
end

-- ─────────────────────────────────────────────────────────────
-- UI constructors
-- ─────────────────────────────────────────────────────────────

function ESP:MakeText(parent)
    local C = self.Config
    local l = Instance.new("TextLabel")
    l.Size                   = UDim2.new(0, 200, 0, 14)
    l.BackgroundTransparency = 1
    l.TextColor3             = Color3.new(1, 1, 1)
    l.TextStrokeTransparency = 0
    l.TextStrokeColor3       = Color3.new(0, 0, 0)
    l.TextScaled             = false
    l.TextSize               = C.Text.Size
    l.Font                   = Fonts[C.Text.Font] or Enum.Font.GothamBold
    l.Text                   = ""
    l.Visible                = false
    l.Parent                 = parent
    return l
end

function ESP:CreateBox(plr)
    local C      = self.Config
    local CoreGui = self.Services.CoreGui

    local gui = Instance.new("ScreenGui")
    gui.Name           = "ESP_Box_" .. plr.Name
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn   = false
    gui.Parent         = CoreGui

    local box = Instance.new("Frame")
    box.BackgroundTransparency = 1
    box.BorderSizePixel        = 0
    box.Visible                = false
    box.Parent                 = gui

    local stroke = Instance.new("UIStroke")
    stroke.Thickness       = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent          = box

    local sgrad = Instance.new("UIGradient")
    sgrad.Rotation = 45
    sgrad.Color    = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   C.Box.Gradient.Color1),
        ColorSequenceKeypoint.new(0.5, C.Box.Gradient.Color2),
        ColorSequenceKeypoint.new(1,   C.Box.Gradient.Color3),
    })
    sgrad.Parent = stroke

    local fill = Instance.new("Frame")
    fill.BackgroundColor3      = Color3.new(1, 1, 1)
    fill.BackgroundTransparency = 0.5
    fill.BorderSizePixel       = 0
    fill.Visible               = false
    fill.Parent                = gui

    local fgrad = Instance.new("UIGradient")
    fgrad.Rotation = C.Box.Filled.Gradient.Rotation.Amount
    fgrad.Parent   = fill

    return { Gui = gui, Box = box, Stroke = stroke, StrokeGrad = sgrad, Fill = fill, FillGrad = fgrad }
end

function ESP:MakeBar(plr, name)
    local C       = self.Config
    local CoreGui = self.Services.CoreGui
    local cfg     = (name == "Health") and C.Bars.Health or C.Bars.Armor

    local gui = Instance.new("ScreenGui")
    gui.Name           = "ESP_" .. name .. "_" .. plr.Name
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.ResetOnSpawn   = false
    gui.Parent         = CoreGui

    local outline = Instance.new("Frame")
    outline.BackgroundColor3      = Color3.new(0, 0, 0)
    outline.BackgroundTransparency = 0.3
    outline.BorderSizePixel       = 0
    outline.Visible               = false
    outline.Parent                = gui

    local fill = Instance.new("Frame")
    fill.BackgroundTransparency = 0
    fill.BorderSizePixel        = 0
    fill.Visible                = false
    fill.Parent                 = outline

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   cfg.Color1),
        ColorSequenceKeypoint.new(0.5, cfg.Color2),
        ColorSequenceKeypoint.new(1,   cfg.Color3),
    })
    grad.Rotation = 90
    grad.Parent   = fill

    return { Gui = gui, Outline = outline, Fill = fill, Gradient = grad }
end

-- ─────────────────────────────────────────────────────────────
-- Highlight / Chams / Material
-- ─────────────────────────────────────────────────────────────

function ESP:MakeHighlight(plr, char)
    self:RemoveHighlight(plr)
    local c = self.Cache[plr]
    if not c then return end
    local C   = self.Config
    local h   = Instance.new("Highlight")
    h.FillColor           = C.Highlight.Color
    h.OutlineColor        = C.Highlight.Outline
    h.FillTransparency    = 0.5
    h.OutlineTransparency = 0
    h.DepthMode           = C.Highlight.BehindWalls
        and Enum.HighlightDepthMode.AlwaysOnTop
        or  Enum.HighlightDepthMode.Occluded
    h.Adornee = char
    h.Parent  = self.Services.CoreGui
    c.Highlight = h
end

function ESP:RemoveHighlight(plr)
    local c = self.Cache[plr]
    if c and c.Highlight then SafeDestroy(c.Highlight); c.Highlight = nil end
end

function ESP:MakeChams(plr, char)
    self:RemoveChams(plr)
    local c = self.Cache[plr]
    if not c then return end
    local C    = self.Config
    local list = {}
    local zidx = C.Chams.BehindWalls and 1 or -1
    for _, p in ipairs(GetBodyParts(char)) do
        local b = Instance.new("BoxHandleAdornment")
        b.Adornee      = p
        b.Color3       = C.Chams.Color
        b.ZIndex       = zidx
        b.AlwaysOnTop  = C.Chams.BehindWalls
        b.Size         = p.Size + ChamsOffset
        b.Transparency = 0.5
        b.Parent       = self.Services.CoreGui
        list[#list + 1] = b
    end
    c.Chams = list
end

function ESP:RemoveChams(plr)
    local c = self.Cache[plr]
    if c and c.Chams then
        for _, v in ipairs(c.Chams) do SafeDestroy(v) end
        c.Chams = nil
    end
end

function ESP:ApplyMaterial(plr, char)
    if not char then return end
    pcall(function()
        if not plr:HasAppearanceLoaded() then
            plr.CharacterAppearanceLoaded:Wait()
        end
    end)
    task.wait(0.2)
    local C   = self.Config
    local mat = C.Material.Material
    local col = C.Material.Color
    for _, p in ipairs(GetBodyParts(char)) do
        pcall(function()
            p.Material = mat; p.Color = col
            if p.Transparency ~= 1 then p.Transparency = 0.5 end
        end)
    end
    for _, a in ipairs(char:GetDescendants()) do
        if a.ClassName == "Accessory" then
            local h = a:FindFirstChild("Handle")
            if h and h:IsA("MeshPart") then
                pcall(function()
                    if not h:GetAttribute(MatAttr) then h:SetAttribute(MatAttr, h.TextureID) end
                    h.Material = mat; h.TextureID = ""; h.Color = col
                end)
            end
        end
    end
    local function strip(obj, attr, prop)
        if obj then pcall(function()
            if obj[prop] ~= "" then obj:SetAttribute(attr, obj[prop]); obj[prop] = "" end
        end) end
    end
    strip(char:FindFirstChildOfClass("Shirt"),        "_OS", "ShirtTemplate")
    strip(char:FindFirstChildOfClass("Pants"),        "_OP", "PantsTemplate")
    strip(char:FindFirstChildOfClass("ShirtGraphic"), "_OG", "Graphic")
end

function ESP:RevertMaterial(plr, char)
    if not char then return end
    for _, p in ipairs(GetBodyParts(char)) do
        pcall(function()
            p.Material = Enum.Material.SmoothPlastic
            if p.Transparency ~= 1 then p.Transparency = 0 end
        end)
    end
    for _, a in ipairs(char:GetDescendants()) do
        if a.ClassName == "Accessory" then
            local h = a:FindFirstChild("Handle")
            if h and h:IsA("MeshPart") then
                pcall(function()
                    local o = h:GetAttribute(MatAttr)
                    if o then h.TextureID = o; h:SetAttribute(MatAttr, nil) end
                    h.Material = Enum.Material.SmoothPlastic; h.Transparency = 0
                end)
            end
        end
    end
    local function restore(obj, attr, prop)
        if obj then pcall(function()
            local o = obj:GetAttribute(attr)
            if o then obj[prop] = o; obj:SetAttribute(attr, nil) end
        end) end
    end
    restore(char:FindFirstChildOfClass("Shirt"),        "_OS", "ShirtTemplate")
    restore(char:FindFirstChildOfClass("Pants"),        "_OP", "PantsTemplate")
    restore(char:FindFirstChildOfClass("ShirtGraphic"), "_OG", "Graphic")
end

-- ─────────────────────────────────────────────────────────────
-- Add player
-- ─────────────────────────────────────────────────────────────

function ESP:AddPlayer(plr)
    local Players = self.Services.Players
    if plr == Players.LocalPlayer then return end
    if self.Cache[plr] then return end

    local CoreGui = self.Services.CoreGui
    local C       = self.Config
    local c       = {}

    c.Box    = self:CreateBox(plr)
    c.BoxGui = c.Box.Gui

    local function makeGui(prefix)
        local g = Instance.new("ScreenGui")
        g.Name         = "ESP_" .. prefix .. "_" .. plr.Name
        g.ResetOnSpawn = false
        g.Parent       = CoreGui
        return g
    end

    c.NameGui = makeGui("N"); c.NameLbl = self:MakeText(c.NameGui)
    c.DistGui = makeGui("D"); c.DistLbl = self:MakeText(c.DistGui)
    c.WeapGui = makeGui("W"); c.WeapLbl = self:MakeText(c.WeapGui)

    c.HpBar  = self:MakeBar(plr, "Health"); c.HpGui  = c.HpBar.Gui
    c.ArmBar = self:MakeBar(plr, "Armor");  c.ArmGui = c.ArmBar.Gui

    c.HpLast  = 1
    c.ArmLast = 0

    self.Cache[plr] = c

    c.CharConn = plr.CharacterAdded:Connect(function(nc)
        c.Character = nc
        c.MatDone   = false
        if C.Highlight.Enabled then self:MakeHighlight(plr, nc) end
        if C.Chams.Enabled     then self:MakeChams(plr, nc)     end
        if C.Material.Enabled  then task.spawn(function() self:ApplyMaterial(plr, nc) end) end
    end)

    local char = plr.Character
    if char then
        c.Character = char
        if C.Highlight.Enabled then self:MakeHighlight(plr, char) end
        if C.Chams.Enabled     then self:MakeChams(plr, char)     end
        if C.Material.Enabled  then task.spawn(function() self:ApplyMaterial(plr, char) end) end
    end
end

-- ─────────────────────────────────────────────────────────────
-- Update
-- ─────────────────────────────────────────────────────────────

local function HideAll(c)
    if c.Box then c.Box.Box.Visible = false; c.Box.Fill.Visible = false end
    if c.NameLbl then c.NameLbl.Visible = false end
    if c.DistLbl then c.DistLbl.Visible = false end
    if c.WeapLbl then c.WeapLbl.Visible = false end
    if c.HpBar  then c.HpBar.Outline.Visible  = false; c.HpBar.Fill.Visible  = false end
    if c.ArmBar then c.ArmBar.Outline.Visible = false; c.ArmBar.Fill.Visible = false end
end

function ESP:Update()
    if not self.Enabled then return end

    local cam = workspace.CurrentCamera
    if not cam then return end

    local C      = self.Config
    local inset  = self.Services.GuiService:GetGuiInset().Y
    local now    = tick()
    local dt     = now - self.FrameTick
    self.FrameTick = now

    for plr, c in pairs(self.Cache) do
        if not plr or not plr.Parent then self:DeletePlayer(plr); continue end

        local char = c.Character or plr.Character
        if char then c.Character = char end
        if not char or not char.Parent then HideAll(c); continue end

        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then HideAll(c); continue end

        local _, sz3, center = CustomBounds(char)
        if not center then HideAll(c); continue end

        local sp, onScreen = cam:WorldToViewportPoint(center)
        if not onScreen or sp.Z <= 0 then HideAll(c); continue end

        local dist   = (cam.CFrame.Position - center).Magnitude
        local fovH   = math.tan(math.rad(cam.FieldOfView / 2)) * 2
        local scaleX = cam.ViewportSize.Y / (fovH * dist) * sz3.X
        local scaleY = cam.ViewportSize.Y / (fovH * dist) * sz3.Y
        if scaleX <= 0 or scaleY <= 0 then HideAll(c); continue end

        local pos = Vector2.new(sp.X - scaleX / 2, sp.Y - scaleY / 2 - inset)

        -- Highlight
        if C.Highlight.Enabled then
            if not c.Highlight then self:MakeHighlight(plr, char) end
            if c.Highlight then
                c.Highlight.FillColor    = C.Highlight.Color
                c.Highlight.OutlineColor = C.Highlight.Outline
                c.Highlight.DepthMode    = C.Highlight.BehindWalls
                    and Enum.HighlightDepthMode.AlwaysOnTop
                    or  Enum.HighlightDepthMode.Occluded
            end
        else self:RemoveHighlight(plr) end

        -- Chams
        if C.Chams.Enabled then
            if not c.Chams then self:MakeChams(plr, char) end
            if c.Chams then
                local zidx = C.Chams.BehindWalls and 1 or -1
                for _, v in ipairs(c.Chams) do
                    pcall(function()
                        v.Color3 = C.Chams.Color
                        v.ZIndex = zidx
                        v.AlwaysOnTop = C.Chams.BehindWalls
                    end)
                end
            end
        else self:RemoveChams(plr) end

        -- Material
        if C.Material.Enabled and not c.MatDone then
            task.spawn(function() self:ApplyMaterial(plr, char) end)
            c.MatDone = true
        elseif not C.Material.Enabled and c.MatDone then
            self:RevertMaterial(plr, char)
            c.MatDone = false
        end

        -- Box
        local bx = c.Box
        if C.Box.Enabled then
            bx.Box.Visible  = true
            bx.Box.Position = UDim2.fromOffset(pos.X, pos.Y)
            bx.Box.Size     = UDim2.fromOffset(scaleX, scaleY)
            bx.StrokeGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0,   C.Box.Gradient.Color1),
                ColorSequenceKeypoint.new(0.5, C.Box.Gradient.Color2),
                ColorSequenceKeypoint.new(1,   C.Box.Gradient.Color3),
            })
            if C.Box.Filled.Enabled then
                bx.Fill.Visible  = true
                bx.Fill.Position = UDim2.fromOffset(pos.X, pos.Y)
                bx.Fill.Size     = UDim2.fromOffset(scaleX, scaleY)
                bx.FillGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0,   C.Box.Filled.Gradient.Color1),
                    ColorSequenceKeypoint.new(0.5, C.Box.Filled.Gradient.Color2),
                    ColorSequenceKeypoint.new(1,   C.Box.Filled.Gradient.Color3),
                })
                if C.Box.Filled.Gradient.Rotation.Moving.Enabled then
                    self.RotationAngle = (self.RotationAngle + dt * C.Box.Filled.Gradient.Rotation.Moving.Speed) % 360
                    bx.FillGrad.Rotation = self.RotationAngle
                else
                    bx.FillGrad.Rotation = C.Box.Filled.Gradient.Rotation.Amount
                end
            else
                bx.Fill.Visible = false
            end
        else
            bx.Box.Visible  = false
            bx.Fill.Visible = false
        end

        -- Bars
        local bw = C.Bars.Width
        local bh = scaleY

        local function drawBar(bar, cfg, val, maxVal, lastKey, extraOff)
            if not bar then return false end
            if not cfg.Enabled then
                bar.Outline.Visible = false; bar.Fill.Visible = false
                return false
            end
            local pct  = math.clamp(val / math.max(maxVal, 1), 0, 1)
            local lerp = c[lastKey] or pct
            lerp = lerp + (pct - lerp) * C.Bars.Lerp
            c[lastKey] = lerp

            local x = pos.X - bw - 4 - (extraOff or 0)
            bar.Outline.Visible = true

            if C.Bars.Resize then
                local ch = math.max(bh * lerp, 2)
                bar.Outline.Position = UDim2.fromOffset(x - 1, pos.Y + bh - ch - 1)
                bar.Outline.Size     = UDim2.fromOffset(bw + 2, ch + 2)
                bar.Fill.Visible     = true
                bar.Fill.Position    = UDim2.fromOffset(1, 1)
                bar.Fill.Size        = UDim2.fromOffset(bw, ch)
            else
                bar.Outline.Position = UDim2.fromOffset(x - 1, pos.Y - 1)
                bar.Outline.Size     = UDim2.fromOffset(bw + 2, bh + 2)
                bar.Fill.Visible     = true
                bar.Fill.Position    = UDim2.fromOffset(1, (1 - lerp) * bh + 1)
                bar.Fill.Size        = UDim2.fromOffset(bw, lerp * bh)
            end

            if bar.Gradient then
                bar.Gradient.Color = (C.Bars.Type == "Gradient")
                    and ColorSequence.new({
                        ColorSequenceKeypoint.new(0,   cfg.Color1),
                        ColorSequenceKeypoint.new(0.5, cfg.Color2),
                        ColorSequenceKeypoint.new(1,   cfg.Color3),
                    })
                    or ColorSequence.new(cfg.Color1)
            end
            return true
        end

        local hpVis = drawBar(c.HpBar, C.Bars.Health, hum.Health, hum.MaxHealth, "HpLast", 0)

        if C.Bars.Armor.Enabled then
            local be  = char:FindFirstChild("BodyEffects")
            local av  = be and be:FindFirstChild("Armor")
            local val = (av and av.Value) or 0
            if C.Bars.Armor.Armored and val <= 0 then
                c.ArmBar.Outline.Visible = false; c.ArmBar.Fill.Visible = false
            else
                drawBar(c.ArmBar, C.Bars.Armor, val, 130, "ArmLast", hpVis and (bw * 2 + 8) or 0)
            end
        else
            c.ArmBar.Outline.Visible = false; c.ArmBar.Fill.Visible = false
        end

        -- Text
        local cx    = pos.X + scaleX / 2
        local topY  = pos.Y
        local botY  = pos.Y + scaleY
        local ts    = C.Text
        local font  = Fonts[C.Text.Font] or Enum.Font.GothamBold
        local tsize = C.Text.Size

        if ts.Name.Enabled then
            local lbl = c.NameLbl
            lbl.Visible    = true
            lbl.Font       = font
            lbl.TextSize   = tsize
            lbl.TextColor3 = ts.Name.Color
            lbl.Text       = GetCase(
                ts.Name.Type == "DisplayName" and plr.DisplayName or plr.Name,
                ts.Name.Casing
            )
            lbl.Position = UDim2.fromOffset(cx - lbl.AbsoluteSize.X / 2, topY - tsize - 2)
        else
            c.NameLbl.Visible = false
        end

        local lineH = tsize + 2
        local wepY, distY

        if ts.Weapon.Enabled and ts.Distance.Enabled then
            wepY = botY + 3; distY = botY + 3 + lineH
        elseif ts.Weapon.Enabled then
            wepY = botY + 3
        elseif ts.Distance.Enabled then
            distY = botY + 3
        end

        if ts.Weapon.Enabled then
            local lbl  = c.WeapLbl
            local tool = char:FindFirstChildOfClass("Tool")
            lbl.Visible    = true
            lbl.Font       = font
            lbl.TextSize   = tsize
            lbl.TextColor3 = ts.Weapon.Color
            lbl.Text       = GetCase(tool and tool.Name or "None", ts.Weapon.Casing)
            lbl.Position   = UDim2.fromOffset(cx - lbl.AbsoluteSize.X / 2, wepY)
        else
            c.WeapLbl.Visible = false
        end

        if ts.Distance.Enabled then
            local lbl = c.DistLbl
            lbl.Visible    = true
            lbl.Font       = font
            lbl.TextSize   = tsize
            lbl.TextColor3 = ts.Distance.Color
            lbl.Text       = GetCase(string.format("[%.0fm]", dist * 0.28), ts.Distance.Casing)
            lbl.Position   = UDim2.fromOffset(cx - lbl.AbsoluteSize.X / 2, distY)
        else
            c.DistLbl.Visible = false
        end
    end
end

-- ─────────────────────────────────────────────────────────────
-- Connections
-- ─────────────────────────────────────────────────────────────

function ESP:SetupConnections()
    local Players    = self.Services.Players
    local RunService = self.Services.RunService

    self.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(p)
        if p ~= Players.LocalPlayer and self.Enabled then
            self:AddPlayer(p)
        end
    end)

    self.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(p)
        self:DeletePlayer(p)
    end)

    self.Connections.Render = RunService.Heartbeat:Connect(function()
        self:Update()
    end)
end

function ESP:DisconnectAll()
    for _, conn in pairs(self.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    self.Connections = {}
end

-- ─────────────────────────────────────────────────────────────
-- CreateUI
-- ─────────────────────────────────────────────────────────────

function ESP:CreateUI(Tab)
    local C = self.Config
    local L = Tab:AddLeftGroupbox("ESP", "eye")
    local R = Tab:AddRightGroupbox("Text & Bars", "type")

    -- Master toggle
    L:AddToggle("ESP_Enabled", {
        Text    = "Enable ESP",
        Default = false,
        Tooltip = "Toggles the entire ESP system.",
        Callback = function(v)
            self.Enabled = v
            local Players = self.Services.Players
            if v then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= Players.LocalPlayer then self:AddPlayer(p) end
                end
            else
                self:Clear()
            end
        end,
    }):AddKeyPicker("ESP_Key", {
        Text            = "Toggle ESP",
        Default         = "None",
        Mode            = "Toggle",
        SyncToggleState = true,
        Callback = function(v)
            self.Enabled = v
            local Players = self.Services.Players
            if v then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= Players.LocalPlayer then self:AddPlayer(p) end
                end
            else
                self:Clear()
            end
        end,
    })

    L:AddDivider()

    -- Box
    L:AddToggle("ESP_Box", {
        Text = "Box", Default = false,
        Callback = function(v) C.Box.Enabled = v end,
    })
    L:AddLabel("Box Gradient")
    L:AddColorPicker("BoxCol1", { Default = C.Box.Gradient.Color1, Callback = function(v) C.Box.Gradient.Color1 = v end })
    L:AddColorPicker("BoxCol2", { Default = C.Box.Gradient.Color2, Callback = function(v) C.Box.Gradient.Color2 = v end })
    L:AddColorPicker("BoxCol3", { Default = C.Box.Gradient.Color3, Callback = function(v) C.Box.Gradient.Color3 = v end })

    L:AddToggle("ESP_Fill", {
        Text = "Filled Box", Default = false,
        Callback = function(v) C.Box.Filled.Enabled = v end,
    })
    L:AddLabel("Fill Gradient")
    L:AddColorPicker("FillCol1", { Default = C.Box.Filled.Gradient.Color1, Callback = function(v) C.Box.Filled.Gradient.Color1 = v end })
    L:AddColorPicker("FillCol2", { Default = C.Box.Filled.Gradient.Color2, Callback = function(v) C.Box.Filled.Gradient.Color2 = v end })
    L:AddColorPicker("FillCol3", { Default = C.Box.Filled.Gradient.Color3, Callback = function(v) C.Box.Filled.Gradient.Color3 = v end })
    L:AddSlider("FillRot", {
        Text = "Fill Rotation", Default = 45, Min = 0, Max = 360, Rounding = 0,
        Callback = function(v) C.Box.Filled.Gradient.Rotation.Amount = v end,
    })
    L:AddToggle("FillMove", {
        Text = "Animate Rotation", Default = false,
        Callback = function(v) C.Box.Filled.Gradient.Rotation.Moving.Enabled = v end,
    })
    L:AddSlider("FillSpeed", {
        Text = "Rotation Speed", Default = 300, Min = 10, Max = 1000, Rounding = 0,
        Callback = function(v) C.Box.Filled.Gradient.Rotation.Moving.Speed = v end,
    })

    L:AddDivider()

    -- Highlight
    L:AddToggle("ESP_HL", {
        Text = "Highlight", Default = false,
        Callback = function(v)
            C.Highlight.Enabled = v
            if not v then for p in pairs(self.Cache) do self:RemoveHighlight(p) end end
        end,
    })
    L:AddColorPicker("HLFill",    { Default = C.Highlight.Color,   Callback = function(v) C.Highlight.Color   = v end })
    L:AddColorPicker("HLOutline", { Default = C.Highlight.Outline, Callback = function(v) C.Highlight.Outline = v end })
    L:AddToggle("HLWalls", {
        Text = "Behind Walls", Default = false,
        Callback = function(v) C.Highlight.BehindWalls = v end,
    })

    L:AddDivider()

    -- Chams
    L:AddToggle("ESP_Chams", {
        Text = "Chams", Default = false,
        Callback = function(v)
            C.Chams.Enabled = v
            if not v then for p in pairs(self.Cache) do self:RemoveChams(p) end end
        end,
    })
    L:AddColorPicker("ChamsCol",   { Default = C.Chams.Color, Callback = function(v) C.Chams.Color = v end })
    L:AddToggle("ChamsWalls", {
        Text = "Behind Walls", Default = false,
        Callback = function(v) C.Chams.BehindWalls = v end,
    })

    L:AddDivider()

    -- Material
    L:AddToggle("ESP_Mat", {
        Text = "Material Override", Default = false,
        Callback = function(v)
            C.Material.Enabled = v
            if not v then
                for p, cc in pairs(self.Cache) do
                    if cc.MatDone then
                        self:RevertMaterial(p, cc.Character)
                        cc.MatDone = false
                    end
                end
            end
        end,
    })
    L:AddColorPicker("MatColor", { Default = C.Material.Color, Callback = function(v) C.Material.Color = v end })
    L:AddDropdown("MatType", {
        Values  = { "ForceField", "Neon", "Glass", "SmoothPlastic" },
        Default = "ForceField",
        Text    = "Material",
        Callback = function(v) C.Material.Material = Enum.Material[v] end,
    })

    -- ── RIGHT ────────────────────────────────────────────────

    -- Name
    R:AddToggle("ESP_Name", {
        Text = "Name", Default = false,
        Callback = function(v) C.Text.Name.Enabled = v end,
    })
    R:AddColorPicker("NameCol", { Default = C.Text.Name.Color, Callback = function(v) C.Text.Name.Color = v end })
    R:AddDropdown("NameType", {
        Values = { "DisplayName", "Username" }, Default = "DisplayName", Text = "Name type",
        Callback = function(v) C.Text.Name.Type = v end,
    })
    R:AddDropdown("NameCase", {
        Values = { "lowercase", "UPPERCASE", "Normal" }, Default = "lowercase", Text = "Name case",
        Callback = function(v) C.Text.Name.Casing = v end,
    })

    R:AddDivider()

    -- Weapon
    R:AddToggle("ESP_Weapon", {
        Text = "Weapon", Default = false,
        Callback = function(v) C.Text.Weapon.Enabled = v end,
    })
    R:AddColorPicker("WeapCol", { Default = C.Text.Weapon.Color, Callback = function(v) C.Text.Weapon.Color = v end })
    R:AddDropdown("WeapCase", {
        Values = { "lowercase", "UPPERCASE", "Normal" }, Default = "lowercase", Text = "Weapon case",
        Callback = function(v) C.Text.Weapon.Casing = v end,
    })

    R:AddDivider()

    -- Distance
    R:AddToggle("ESP_Dist", {
        Text = "Distance", Default = false,
        Callback = function(v) C.Text.Distance.Enabled = v end,
    })
    R:AddColorPicker("DistCol", { Default = C.Text.Distance.Color, Callback = function(v) C.Text.Distance.Color = v end })
    R:AddDropdown("DistCase", {
        Values = { "lowercase", "UPPERCASE", "Normal" }, Default = "lowercase", Text = "Distance case",
        Callback = function(v) C.Text.Distance.Casing = v end,
    })

    R:AddDivider()

    -- Font & Size
    R:AddDropdown("ESP_Font", {
        Values  = { "SourceSans", "SourceSansBold", "Gotham", "GothamBold", "Minecraft", "Cartoon" },
        Default = "GothamBold",
        Text    = "Font",
        Callback = function(v) C.Text.Font = v end,
    })
    R:AddSlider("ESP_TextSize", {
        Text = "Text Size", Default = 10, Min = 6, Max = 24, Rounding = 0,
        Callback = function(v)
            C.Text.Size = v
            for _, cc in pairs(self.Cache) do
                if cc.NameLbl then cc.NameLbl.TextSize = v end
                if cc.DistLbl then cc.DistLbl.TextSize = v end
                if cc.WeapLbl then cc.WeapLbl.TextSize = v end
            end
        end,
    })

    R:AddDivider()

    -- Health Bar
    R:AddToggle("ESP_HP", {
        Text = "Health Bar", Default = false,
        Callback = function(v) C.Bars.Health.Enabled = v end,
    })
    R:AddColorPicker("HP1", { Default = C.Bars.Health.Color1, Callback = function(v) C.Bars.Health.Color1 = v end })
    R:AddColorPicker("HP2", { Default = C.Bars.Health.Color2, Callback = function(v) C.Bars.Health.Color2 = v end })
    R:AddColorPicker("HP3", { Default = C.Bars.Health.Color3, Callback = function(v) C.Bars.Health.Color3 = v end })

    R:AddDivider()

    -- Armor Bar
    R:AddToggle("ESP_Armor", {
        Text = "Armor Bar", Default = false,
        Callback = function(v) C.Bars.Armor.Enabled = v end,
    })
    R:AddColorPicker("Arm1", { Default = C.Bars.Armor.Color1, Callback = function(v) C.Bars.Armor.Color1 = v end })
    R:AddColorPicker("Arm2", { Default = C.Bars.Armor.Color2, Callback = function(v) C.Bars.Armor.Color2 = v end })
    R:AddColorPicker("Arm3", { Default = C.Bars.Armor.Color3, Callback = function(v) C.Bars.Armor.Color3 = v end })
    R:AddToggle("ArmorOnly", {
        Text = "Show Only When Armored", Default = false,
        Callback = function(v) C.Bars.Armor.Armored = v end,
    })

    R:AddDivider()

    -- Bar settings
    R:AddSlider("BarWidth", {
        Text = "Bar Width", Default = 2.5, Min = 1, Max = 8, Rounding = 1,
        Callback = function(v) C.Bars.Width = v end,
    })
    R:AddSlider("BarSmooth", {
        Text = "Bar Smoothing", Default = 0.05, Min = 0.01, Max = 1, Rounding = 2,
        Callback = function(v) C.Bars.Lerp = v end,
    })
    R:AddToggle("BarResize", {
        Text = "Resize Bars", Default = false,
        Callback = function(v) C.Bars.Resize = v end,
    })
    R:AddDropdown("BarStyle", {
        Values  = { "Gradient", "Solid Color" },
        Default = "Gradient",
        Text    = "Bar Style",
        Callback = function(v) C.Bars.Type = v end,
    })
end

-- ─────────────────────────────────────────────────────────────
-- Cleanup
-- ─────────────────────────────────────────────────────────────

function ESP:Cleanup()
    self.Enabled = false
    self:DisconnectAll()
    self:Clear()
end

return ESP
