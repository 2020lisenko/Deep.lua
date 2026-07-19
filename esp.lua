local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")

local ESP = {
    Enabled = false,
    Cache = {},
    Connections = {},
    FrameTick = tick(),
    RotationAngle = -45,
    Config = {
        Box = {
            Enabled = false,
            Inline = Color3.fromRGB(0, 0, 0),
            Outline = Color3.fromRGB(0, 0, 0),
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
                        Moving = {
                            Enabled = false,
                            Speed = 300,
                        },
                    },
                },
            },
        },
        Text = {
            Font = "GothamBold",
            Name = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Type = "DisplayName", Casing = "lowercase" },
            Weapon = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Casing = "lowercase" },
            Distance = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Casing = "lowercase" },
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
                Color3 = Color3.fromRGB(255, 0, 0),
            },
            Armor = {
                Enabled = false,
                Color1 = Color3.fromRGB(0, 0, 255),
                Color2 = Color3.fromRGB(135, 206, 235),
                Color3 = Color3.fromRGB(1, 0, 0),
                Armored = false,
            },
        },
        Material = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.ForceField },
        Highlight = { Enabled = false, BehindWalls = false, Color = Color3.fromRGB(255, 255, 255), Outline = Color3.fromRGB(0, 0, 0) },
        Chams = { Enabled = false, BehindWalls = false, Color = Color3.fromRGB(255, 255, 255) },
    },
}

local C = ESP.Config
local Vertices = {
    {-0.5,-0.5,-0.5},{-0.5,0.5,-0.5},{0.5,-0.5,-0.5},{0.5,0.5,-0.5},
    {-0.5,-0.5,0.5},{-0.5,0.5,0.5},{0.5,-0.5,0.5},{0.5,0.5,0.5},
}
local Increase = Vector3.new(2, 2, 2)
local ChamsOffset = Vector3.new(0.01, 0.01, 0.01)
local MatAttr = ("ESP_Mat_%d"):format(math.random(10000, 99999))
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

local function GetBodyParts(char)
    local parts = {}
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("BasePart") and c.Name ~= "HumanoidRootPart" then
            parts[#parts+1] = c
        end
    end
    return parts
end

local function CustomBounds(model)
    local mn = Vector3.new(math.huge, math.huge, math.huge)
    local mx = Vector3.new(-math.huge, -math.huge, -math.huge)
    for _, p in ipairs(model:GetChildren()) do
        if p:IsA("BasePart") then
            local cf, sz = p.CFrame, p.Size
            for _, v in ipairs(Vertices) do
                local ws = cf:PointToWorldSpace(Vector3.new(v[1]*sz.X, (v[2]+0.2)*(sz.Y+0.2), v[3]*sz.Z))
                mn = Vector3.new(math.min(mn.X, ws.X), math.min(mn.Y, ws.Y), math.min(mn.Z, ws.Z))
                mx = Vector3.new(math.max(mx.X, ws.X), math.max(mx.Y, ws.Y), math.max(mx.Z, ws.Z))
            end
        end
    end
    if mn == Vector3.new(math.huge, math.huge, math.huge) then return end
    local center = (mn+mx)/2
    return CFrame.new(center), mx-mn+Increase, center
end

local function GetCase(text, ct)
    ct = ct or "lowercase"
    if ct == "UPPERCASE" then return text:upper() end
    if ct == "lowercase" then return text:lower() end
    return text
end

function ESP:DeletePlayer(plr)
    local c = ESP.Cache[plr]
    if not c then return end
    if c.BoxGui then c.BoxGui:Destroy() end
    for _, k in ipairs({"NameGui","DistGui","WeapGui","HpGui","ArmGui"}) do
        if c[k] then c[k]:Destroy() end
    end
    if c.Highlight then c.Highlight:Destroy() end
    if c.Chams then for _, v in ipairs(c.Chams) do pcall(v.Destroy, v) end end
    if c.CharConn then c.CharConn:Disconnect() end
    ESP.Cache[plr] = nil
end

function ESP:Clear()
    for p in pairs(ESP.Cache) do ESP:DeletePlayer(p) end
    ESP.Cache = {}
end

function ESP:MakeText(parent)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(0, 4, 0, 4)
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.new(1,1,1)
    l.TextStrokeTransparency = 0
    l.TextScaled = false
    l.TextSize = 10
    l.TextStrokeColor3 = Color3.new(0,0,0)
    l.FontFace = Fonts[C.Text.Font]
    l.Text = ""
    l.Parent = parent
    return l
end

function ESP:CreateBox(plr)
    local gui = Instance.new("ScreenGui")
    gui.Name = "ESP_Box_"..plr.Name
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = CoreGui

    local box = Instance.new("Frame")
    box.Name = "Box_"..plr.Name
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Parent = gui

    local stroke = Instance.new("UIStroke")
    stroke.Name = "Stroke"
    stroke.Thickness = 2
    stroke.Color = Color3.new(1,1,1)
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = box

    local sgrad = Instance.new("UIGradient")
    sgrad.Name = "Gradient"
    sgrad.Rotation = 45
    sgrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.Box.Gradient.Color1),
        ColorSequenceKeypoint.new(0.5, C.Box.Gradient.Color2),
        ColorSequenceKeypoint.new(1, C.Box.Gradient.Color3),
    })
    sgrad.Parent = stroke

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = Color3.new(1,1,1)
    fill.BackgroundTransparency = 0.5
    fill.BorderSizePixel = 0
    fill.Visible = false
    fill.Parent = gui
    fill.ZIndex = -1

    local fgrad = Instance.new("UIGradient")
    fgrad.Name = "FillGrad"
    fgrad.Rotation = C.Box.Filled.Gradient.Rotation.Amount
    fgrad.Parent = fill

    return { Gui = gui, Box = box, Stroke = stroke, StrokeGrad = sgrad, FillGrad = fgrad, Fill = fill }
end

function ESP:MakeBar(plr, name)
    local cfg = name == "Health" and C.Bars.Health or C.Bars.Armor
    local gui = Instance.new("ScreenGui")
    gui.Name = "ESP_"..name.."_"..plr.Name
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = CoreGui

    local outline = Instance.new("Frame")
    outline.BackgroundColor3 = Color3.new(0,0,0)
    outline.BorderSizePixel = 0
    outline.Parent = gui

    local fill = Instance.new("Frame")
    fill.BackgroundTransparency = 0
    fill.BorderSizePixel = 0
    fill.Parent = outline

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, cfg.Color1),
        ColorSequenceKeypoint.new(0.5, cfg.Color2),
        ColorSequenceKeypoint.new(1, cfg.Color3),
    })
    grad.Rotation = 90
    grad.Parent = fill

    return { Gui = gui, Outline = outline, Fill = fill, Gradient = grad }
end

function ESP:MakeHighlight(plr, char)
    ESP:RemoveHighlight(plr)
    local h = Instance.new("Highlight")
    h.FillColor = C.Highlight.Color
    h.OutlineColor = C.Highlight.Outline
    h.DepthMode = C.Highlight.BehindWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    h.Adornee = char
    h.Parent = CoreGui
    if ESP.Cache[plr] then ESP.Cache[plr].Highlight = h end
end

function ESP:RemoveHighlight(plr)
    local c = ESP.Cache[plr]
    if c and c.Highlight then c.Highlight:Destroy(); c.Highlight = nil end
end

function ESP:MakeChams(plr, char)
    ESP:RemoveChams(plr)
    local list = {}
    local z = C.Chams.BehindWalls and 1 or -1
    for _, p in ipairs(GetBodyParts(char)) do
        local b = Instance.new("BoxHandleAdornment")
        b.Adornee = p; b.Color3 = C.Chams.Color
        b.ZIndex = z; b.AlwaysOnTop = C.Chams.BehindWalls
        b.Size = p.Size + ChamsOffset; b.Transparency = 0.5
        b.Parent = CoreGui; list[#list+1] = b
    end
    if ESP.Cache[plr] then ESP.Cache[plr].Chams = list end
end

function ESP:RemoveChams(plr)
    local c = ESP.Cache[plr]
    if c and c.Chams then
        for _, v in ipairs(c.Chams) do pcall(v.Destroy, v) end
        c.Chams = nil
    end
end

function ESP:ApplyMaterial(plr, char)
    if not char then return end
    if not plr:HasAppearanceLoaded() then plr.CharacterAppearanceLoaded:Wait() end
    task.wait(0.2)
    local mat = C.Material.Material; local col = C.Material.Color
    for _, p in ipairs(GetBodyParts(char)) do
        p.Material = mat; p.Color = col
        if p.Transparency ~= 1 then p.Transparency = 0.5 end
    end
    for _, a in ipairs(char:GetDescendants()) do
        if a.ClassName == "Accessory" then
            local h = a:FindFirstChild("Handle")
            if h and h:IsA("MeshPart") then
                if not h:GetAttribute(MatAttr) then h:SetAttribute(MatAttr, h.TextureID) end
                h.Material = mat; h.TextureID = ""; h.Color = col
            end
        end
    end
    local function strip(obj, attr, prop)
        if obj and obj[prop] ~= "" then obj:SetAttribute(attr, obj[prop]); obj[prop] = "" end
    end
    strip(char:FindFirstChildOfClass("Shirt"), "_OS", "ShirtTemplate")
    strip(char:FindFirstChildOfClass("Pants"), "_OP", "PantsTemplate")
    strip(char:FindFirstChildOfClass("ShirtGraphic"), "_OG", "Graphic")
end

function ESP:RevertMaterial(plr, char)
    if not char then return end
    for _, p in ipairs(GetBodyParts(char)) do
        p.Material = Enum.Material.SmoothPlastic
        if p.Transparency ~= 1 then p.Transparency = 0 end
    end
    for _, a in ipairs(char:GetDescendants()) do
        if a.ClassName == "Accessory" then
            local h = a:FindFirstChild("Handle")
            if h and h:IsA("MeshPart") then
                local o = h:GetAttribute(MatAttr)
                if o then h.TextureID = o; h:SetAttribute(MatAttr, nil) end
                h.Material = Enum.Material.SmoothPlastic; h.Transparency = 0
            end
        end
    end
    local function restore(obj, attr, prop)
        if obj then local o = obj:GetAttribute(attr); if o then obj[prop] = o; obj:SetAttribute(attr, nil) end end
    end
    restore(char:FindFirstChildOfClass("Shirt"), "_OS", "ShirtTemplate")
    restore(char:FindFirstChildOfClass("Pants"), "_OP", "PantsTemplate")
    restore(char:FindFirstChildOfClass("ShirtGraphic"), "_OG", "Graphic")
end

function ESP:AddPlayer(plr)
    if plr == Players.LocalPlayer then return end
    local c = {}
    c.Box = ESP:CreateBox(plr)
    c.BoxGui = c.Box.Gui
    local ng = Instance.new("ScreenGui"); ng.Name = "ESP_N_"..plr.Name; ng.Parent = CoreGui
    c.NameGui = ng; c.NameLbl = ESP:MakeText(ng)
    local dg = Instance.new("ScreenGui"); dg.Name = "ESP_D_"..plr.Name; dg.Parent = CoreGui
    c.DistGui = dg; c.DistLbl = ESP:MakeText(dg)
    local wg = Instance.new("ScreenGui"); wg.Name = "ESP_W_"..plr.Name; wg.Parent = CoreGui
    c.WeapGui = wg; c.WeapLbl = ESP:MakeText(wg)
    c.HpBar = ESP:MakeBar(plr, "Health"); c.HpGui = c.HpBar.Gui
    c.ArmBar = ESP:MakeBar(plr, "Armor"); c.ArmGui = c.ArmBar.Gui
    c.HpLast = 1; c.ArmLast = 0
    c.CharConn = plr.CharacterAdded:Connect(function(nc)
        c.Character = nc
        if C.Highlight.Enabled then ESP:MakeHighlight(plr, nc) end
        if C.Chams.Enabled then ESP:MakeChams(plr, nc) end
        if C.Material.Enabled then task.spawn(ESP.ApplyMaterial, ESP, plr, nc) end
    end)
    ESP.Cache[plr] = c
    local char = plr.Character
    if char then
        c.Character = char
        if C.Highlight.Enabled then ESP:MakeHighlight(plr, char) end
        if C.Chams.Enabled then ESP:MakeChams(plr, char) end
        if C.Material.Enabled then task.spawn(ESP.ApplyMaterial, ESP, plr, char) end
    end
end

function ESP:Update()
    if not ESP.Enabled then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    local inset = GuiService:GetGuiInset().Y
    local now = tick()
    local dt = now - ESP.FrameTick
    ESP.FrameTick = now

    for plr, c in pairs(ESP.Cache) do
        if not plr then continue end
        local char = plr.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then continue end

        local cf, sz3, center = CustomBounds(char)
        if not cf then continue end
        local sp, on = cam:WorldToViewportPoint(center)
        if not on then
            if c.Box.Box then c.Box.Box.Visible = false end
            if c.NameLbl then c.NameLbl.Visible = false end
            if c.DistLbl then c.DistLbl.Visible = false end
            if c.WeapLbl then c.WeapLbl.Visible = false end
            if c.HpBar then c.HpBar.Outline.Visible = false; c.HpBar.Fill.Visible = false end
            if c.ArmBar then c.ArmBar.Outline.Visible = false; c.ArmBar.Fill.Visible = false end
            continue
        end

        local dist = (cam.CFrame.Position - center).Magnitude
        local h = math.tan(math.rad(cam.FieldOfView/2)) * 2 * dist
        local scale = Vector2.new(cam.ViewportSize.Y/h * sz3.X, cam.ViewportSize.Y/h * sz3.Y)
        local pos = Vector2.new(sp.X - scale.X/2, sp.Y - scale.Y/2)
        local by = pos.Y - inset

        -- Highlight
        if C.Highlight.Enabled then
            if not c.Highlight then ESP:MakeHighlight(plr, char) end
            if c.Highlight then
                c.Highlight.FillColor = C.Highlight.Color
                c.Highlight.OutlineColor = C.Highlight.Outline
                c.Highlight.DepthMode = C.Highlight.BehindWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            end
        else ESP:RemoveHighlight(plr) end

        -- Chams
        if C.Chams.Enabled then
            if not c.Chams then ESP:MakeChams(plr, char) end
            local z = C.Chams.BehindWalls and 1 or -1
            for _, v in ipairs(c.Chams or {}) do v.Color3 = C.Chams.Color; v.ZIndex = z; v.AlwaysOnTop = C.Chams.BehindWalls end
        else ESP:RemoveChams(plr) end

        -- Material
        if C.Material.Enabled and not c.MatDone then
            task.spawn(ESP.ApplyMaterial, ESP, plr, char); c.MatDone = true
        elseif not C.Material.Enabled and c.MatDone then
            ESP:RevertMaterial(plr, char); c.MatDone = false
        end

        -- Box
        local bx = c.Box
        if C.Box.Enabled then
            bx.Box.Visible = true
            bx.Box.Position = UDim2.fromOffset(pos.X, by)
            bx.Box.Size = UDim2.fromOffset(scale.X, scale.Y)
            bx.StrokeGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, C.Box.Gradient.Color1),
                ColorSequenceKeypoint.new(0.5, C.Box.Gradient.Color2),
                ColorSequenceKeypoint.new(1, C.Box.Gradient.Color3),
            })
            if C.Box.Filled.Enabled then
                bx.Fill.Visible = true
                bx.Fill.Position = UDim2.fromOffset(pos.X, by)
                bx.Fill.Size = UDim2.fromOffset(scale.X, scale.Y)
                bx.FillGrad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, C.Box.Filled.Gradient.Color1),
                    ColorSequenceKeypoint.new(0.5, C.Box.Filled.Gradient.Color2),
                    ColorSequenceKeypoint.new(1, C.Box.Filled.Gradient.Color3),
                })
                if C.Box.Filled.Gradient.Rotation.Moving.Enabled then
                    ESP.RotationAngle = (ESP.RotationAngle + dt * C.Box.Filled.Gradient.Rotation.Moving.Speed) % 360
                    bx.FillGrad.Rotation = ESP.RotationAngle
                else
                    bx.FillGrad.Rotation = C.Box.Filled.Gradient.Rotation.Amount
                end
            else
                bx.Fill.Visible = false
            end
        else
            bx.Box.Visible = false
        end

        -- Bars
        local bw = C.Bars.Width
        local bh = scale.Y
        local baseX = pos.X
        local function drawBar(bar, cfg, val, maxVal, lastKey, offX)
            if not bar then return false end
            if cfg.Enabled then
                local pct = math.clamp(val / maxVal, 0, 1)
                local lerp = c[lastKey] or pct
                lerp = lerp + (pct - lerp) * C.Bars.Lerp
                c[lastKey] = lerp
                local x = baseX - (bw + 4) - offX
                local out = bar.Outline; local fill = bar.Fill
                out.Visible = true
                if C.Bars.Resize then
                    local ch = math.max(bh * lerp, 2)
                    out.Position = UDim2.fromOffset(x-1, by+bh-ch-1)
                    out.Size = UDim2.fromOffset(bw+2, ch+2)
                    fill.Visible = true; fill.Position = UDim2.fromOffset(1, 1)
                    fill.Size = UDim2.fromOffset(bw, ch)
                else
                    out.Position = UDim2.fromOffset(x-1, by-1)
                    out.Size = UDim2.fromOffset(bw+2, bh+2)
                    fill.Visible = true
                    fill.Position = UDim2.fromOffset(1, (1-lerp)*bh+1)
                    fill.Size = UDim2.fromOffset(bw, lerp*bh)
                end
                out.BackgroundTransparency = 0.2
                if bar.Gradient then
                    if C.Bars.Type == "Gradient" then
                        bar.Gradient.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, cfg.Color1),
                            ColorSequenceKeypoint.new(0.5, cfg.Color2),
                            ColorSequenceKeypoint.new(1, cfg.Color3),
                        })
                    else
                        bar.Gradient.Color = ColorSequence.new(cfg.Color1)
                    end
                end
                return true
            else
                out.Visible = false; fill.Visible = false
                return false
            end
        end

        local hpVis = drawBar(c.HpBar, C.Bars.Health, hum.Health, hum.MaxHealth, "HpLast", 0)
        if C.Bars.Armor.Enabled then
            local be = char:FindFirstChild("BodyEffects")
            local av = be and be:FindFirstChild("Armor")
            local val = av and av.Value or 0
            if C.Bars.Armor.Armored and val <= 0 then
                c.ArmBar.Outline.Visible = false; c.ArmBar.Fill.Visible = false
            else
                drawBar(c.ArmBar, C.Bars.Armor, val, 130, "ArmLast", hpVis and (bw*2+6+2) or 0)
            end
        else
            c.ArmBar.Outline.Visible = false; c.ArmBar.Fill.Visible = false
        end

        -- Text
        local cx = pos.X + scale.X/2
        local cy = pos.Y
        local ts = C.Text
        local font = Fonts[C.Text.Font] or Fonts.GothamBold

        if ts.Name.Enabled then
            c.NameLbl.Visible = true
            c.NameLbl.Text = GetCase(ts.Name.Type == "DisplayName" and plr.DisplayName or plr.Name, ts.Name.Casing)
            c.NameLbl.TextColor3 = ts.Name.Color; c.NameLbl.FontFace = font
            c.NameLbl.Position = UDim2.fromOffset(cx - c.NameLbl.AbsoluteSize.X/2, cy - 15 + 6 - inset)
        else
            c.NameLbl.Visible = false
        end

        local wepY, distY
        if ts.Weapon.Enabled and ts.Distance.Enabled then
            wepY = cy + scale.Y + 5 - inset; distY = cy + scale.Y + 15 - inset
        elseif ts.Weapon.Enabled then
            wepY = cy + scale.Y + 5 - inset
        elseif ts.Distance.Enabled then
            distY = cy + scale.Y + 5 - inset
        end

        if ts.Weapon.Enabled then
            c.WeapLbl.Visible = true
            c.WeapLbl.Text = GetCase(char:FindFirstChildOfClass("Tool") and char:FindFirstChildOfClass("Tool").Name or "None", ts.Weapon.Casing)
            c.WeapLbl.TextColor3 = ts.Weapon.Color; c.WeapLbl.FontFace = font
            c.WeapLbl.Position = UDim2.fromOffset(cx - c.WeapLbl.AbsoluteSize.X/2, wepY)
        else
            c.WeapLbl.Visible = false
        end

        if ts.Distance.Enabled then
            c.DistLbl.Visible = true
            c.DistLbl.Text = GetCase(string.format("[%.0f]", dist*0.28), ts.Distance.Casing)
            c.DistLbl.TextColor3 = ts.Distance.Color; c.DistLbl.FontFace = font
            c.DistLbl.Position = UDim2.fromOffset(cx - c.DistLbl.AbsoluteSize.X/2, distY)
        else
            c.DistLbl.Visible = false
        end
    end
end

function ESP:Initialize(tab)
    local L = tab:AddLeftGroupbox("Box")
    local R = tab:AddRightGroupbox("Text & Bars")

    -- Box toggle
    local bt = L:AddToggle("ESP_Box", { Text = "Box", Default = false, Callback = function(v) C.Box.Enabled = v end })

    -- Box Gradient colors (3-point)
    local bColors = L:AddLabel("Box Gradient Colors", "palette")
    bColors:AddColorPicker("BoxCol1", { Default = C.Box.Gradient.Color1, Callback = function(v) C.Box.Gradient.Color1 = v end })
    bColors:AddColorPicker("BoxCol2", { Default = C.Box.Gradient.Color2, Callback = function(v) C.Box.Gradient.Color2 = v end })
    bColors:AddColorPicker("BoxCol3", { Default = C.Box.Gradient.Color3, Callback = function(v) C.Box.Gradient.Color3 = v end })

    -- Filled box
    local ft = L:AddToggle("ESP_Fill", { Text = "Filled Box", Default = false, Callback = function(v) C.Box.Filled.Enabled = v end })
    L:AddLabel("Fill Gradient", "palette"):AddColorPicker("FillCol1", { Default = C.Box.Filled.Gradient.Color1, Callback = function(v) C.Box.Filled.Gradient.Color1 = v end })
    L:AddColorPicker("FillCol2", { Default = C.Box.Filled.Gradient.Color2, Callback = function(v) C.Box.Filled.Gradient.Color2 = v end })
    L:AddColorPicker("FillCol3", { Default = C.Box.Filled.Gradient.Color3, Callback = function(v) C.Box.Filled.Gradient.Color3 = v end })

    L:AddSlider("FillRot", { Text = "Fill Rotation", Default = 45, Min = 0, Max = 360, Rounding = 0, Callback = function(v) C.Box.Filled.Gradient.Rotation.Amount = v end })
    local fm = L:AddToggle("FillMove", { Text = "Animate Rotation", Default = false, Callback = function(v) C.Box.Filled.Gradient.Rotation.Moving.Enabled = v end })
    fm:AddSlider("FillSpeed", { Text = "Speed", Default = 300, Min = 10, Max = 1000, Rounding = 0, Callback = function(v) C.Box.Filled.Gradient.Rotation.Moving.Speed = v end })

    L:AddDivider()

    -- Highlight
    local ht = L:AddToggle("ESP_HL", { Text = "Highlight", Default = false, Callback = function(v)
        C.Highlight.Enabled = v
        if not v then for p in pairs(ESP.Cache) do ESP:RemoveHighlight(p) end end
    end })
    ht:AddColorPicker("HLCol", { Default = C.Highlight.Color, Callback = function(v) C.Highlight.Color = v end })
    ht:AddColorPicker("HLOut", { Default = C.Highlight.Outline, Callback = function(v) C.Highlight.Outline = v end })
    L:AddToggle("HLWalls", { Text = "Behind Walls", Default = false, Callback = function(v) C.Highlight.BehindWalls = v end })

    -- Chams
    local ct = L:AddToggle("ESP_Ch", { Text = "Chams", Default = false, Callback = function(v)
        C.Chams.Enabled = v
        if not v then for p in pairs(ESP.Cache) do ESP:RemoveChams(p) end end
    end })
    ct:AddColorPicker("ChCol", { Default = C.Chams.Color, Callback = function(v) C.Chams.Color = v end })
    L:AddToggle("ChWalls", { Text = "Behind Walls", Default = false, Callback = function(v) C.Chams.BehindWalls = v end })

    L:AddDivider()

    -- Material
    local mt = L:AddToggle("ESP_Mat", { Text = "Material Override", Default = false, Callback = function(v)
        C.Material.Enabled = v
        if not v then for p, c in pairs(ESP.Cache) do if c.MatDone then ESP:RevertMaterial(p, c.Character); c.MatDone = false end end end
    end })
    mt:AddColorPicker("MatCol", { Default = C.Material.Color, Callback = function(v) C.Material.Color = v end })
    L:AddDropdown("MatType", { Values = {"ForceField","Neon","Glass","SmoothPlastic"}, Default = "ForceField", Text = "Material", Callback = function(v) C.Material.Material = Enum.Material[v] end })

    -- Text
    R:AddDivider()
    local nt = R:AddToggle("ESP_Nm", { Text = "Name", Default = false, Callback = function(v) C.Text.Name.Enabled = v end })
    nt:AddColorPicker("NmCol", { Default = C.Text.Name.Color, Callback = function(v) C.Text.Name.Color = v end })
    R:AddDropdown("NmMode", { Values = {"DisplayName","Username"}, Default = "DisplayName", Text = "Type", Callback = function(v) C.Text.Name.Type = v end })
    R:AddDropdown("NmCase", { Values = {"lowercase","UPPERCASE","Normal"}, Default = "lowercase", Text = "Case", Callback = function(v) C.Text.Name.Casing = v end })

    local wt = R:AddToggle("ESP_Wp", { Text = "Weapon", Default = false, Callback = function(v) C.Text.Weapon.Enabled = v end })
    wt:AddColorPicker("WpCol", { Default = C.Text.Weapon.Color, Callback = function(v) C.Text.Weapon.Color = v end })
    R:AddDropdown("WpCase", { Values = {"lowercase","UPPERCASE","Normal"}, Default = "lowercase", Text = "Case", Callback = function(v) C.Text.Weapon.Casing = v end })

    local dt = R:AddToggle("ESP_Dt", { Text = "Distance", Default = false, Callback = function(v) C.Text.Distance.Enabled = v end })
    dt:AddColorPicker("DtCol", { Default = C.Text.Distance.Color, Callback = function(v) C.Text.Distance.Color = v end })
    R:AddDropdown("DtCase", { Values = {"lowercase","UPPERCASE","Normal"}, Default = "lowercase", Text = "Case", Callback = function(v) C.Text.Distance.Casing = v end })

    R:AddDropdown("ESPFont", { Values = {"SourceSans","Gotham","GothamBold","Minecraft","Cartoon"}, Default = "GothamBold", Text = "Font", Callback = function(v) C.Text.Font = v end })
    R:AddSlider("TxtSize", { Text = "Text Size", Default = 10, Min = 6, Max = 20, Rounding = 0, Callback = function(v) for _, p in pairs(ESP.Cache) do end end })

    R:AddDivider()

    -- Health Bar
    local hb = R:AddToggle("HP_Hp", { Text = "Health Bar", Default = false, Callback = function(v) C.Bars.Health.Enabled = v end })
    hb:AddColorPicker("Hp1", { Default = C.Bars.Health.Color1, Callback = function(v) C.Bars.Health.Color1 = v end })
    hb:AddColorPicker("Hp2", { Default = C.Bars.Health.Color2, Callback = function(v) C.Bars.Health.Color2 = v end })
    hb:AddColorPicker("Hp3", { Default = C.Bars.Health.Color3, Callback = function(v) C.Bars.Health.Color3 = v end })

    local ab = R:AddToggle("HP_Arm", { Text = "Armor Bar", Default = false, Callback = function(v) C.Bars.Armor.Enabled = v end })
    ab:AddColorPicker("Ar1", { Default = C.Bars.Armor.Color1, Callback = function(v) C.Bars.Armor.Color1 = v end })
    ab:AddColorPicker("Ar2", { Default = C.Bars.Armor.Color2, Callback = function(v) C.Bars.Armor.Color2 = v end })
    ab:AddColorPicker("Ar3", { Default = C.Bars.Armor.Color3, Callback = function(v) C.Bars.Armor.Color3 = v end })
    ab:AddToggle("ArmOnly", { Text = "Show When Armored", Default = false, Callback = function(v) C.Bars.Armor.Armored = v end })

    R:AddSlider("BarW", { Text = "Bar Width", Default = 2.5, Min = 1, Max = 6, Rounding = 1, Callback = function(v) C.Bars.Width = v end })
    R:AddSlider("BarLerp", { Text = "Bar Smoothing", Default = 0.05, Min = 0.01, Max = 1, Rounding = 2, Callback = function(v) C.Bars.Lerp = v end })
    R:AddToggle("BarResize", { Text = "Resize Bars", Default = false, Callback = function(v) C.Bars.Resize = v end })
    R:AddDropdown("BarType", { Values = {"Gradient","Solid Color"}, Default = "Gradient", Text = "Bar Style", Callback = function(v) C.Bars.Type = v end })

    R:AddDivider()

    local en = R:AddToggle("ESP_On", { Text = "Enable ESP", Default = false, Callback = function(v)
        ESP.Enabled = v
        if v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Players.LocalPlayer then ESP:AddPlayer(p) end
            end
        else
            ESP:Clear()
        end
    end })
    en:AddKeyPicker("ESP_Key", { Text = "Toggle", Default = "None", Mode = "Toggle", SyncToggleState = true, Callback = function(v)
        ESP.Enabled = v
        if v then
            for _, p in ipairs(Players:GetPlayers()) do if p ~= Players.LocalPlayer then ESP:AddPlayer(p) end end
        else
            ESP:Clear()
        end
    end })

    return ESP
end

function ESP:Cleanup()
    ESP.Enabled = false
    for _, c in pairs(ESP.Connections) do
        pcall(c.Disconnect, c)
    end
    ESP.Connections = {}
    ESP:Clear()
end

-- Start connections
ESP.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(p)
    if p ~= Players.LocalPlayer and ESP.Enabled then ESP:AddPlayer(p) end
end)
ESP.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(p)
    if p ~= Players.LocalPlayer then ESP:DeletePlayer(p) end
end)
ESP.Connections.Render = RunService.Heartbeat:Connect(function()
    ESP:Update()
end)

return ESP