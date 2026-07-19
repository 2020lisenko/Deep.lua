local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")

local ESP = {
    Enabled = false,
    Cache = {},
    Connections = {},
    Config = {
        Box = { Enabled = false, Color = Color3.fromRGB(255,255,255), Filled = false, FillColor = Color3.fromRGB(255,255,255), FillTrans = 0.5 },
        Name = { Enabled = false, Color = Color3.fromRGB(255,255,255), Mode = "DisplayName" },
        Distance = { Enabled = false, Color = Color3.fromRGB(255,255,255) },
        Weapon = { Enabled = false, Color = Color3.fromRGB(255,255,255) },
        HealthBar = { Enabled = false, Color = Color3.fromRGB(0,255,0) },
        ArmorBar = { Enabled = false, Color = Color3.fromRGB(0,0,255) },
        Highlight = { Enabled = false, Color = Color3.fromRGB(255,255,255), Outline = Color3.fromRGB(0,0,0), BehindWalls = false },
        Chams = { Enabled = false, Color = Color3.fromRGB(255,255,255), BehindWalls = false },
        Material = { Enabled = false, Color = Color3.fromRGB(255,255,255), Type = Enum.Material.ForceField },
        Font = "SourceSans Bold",
        TextSize = 12,
    },
    Fonts = {
        ["SourceSans"] = Enum.Font.SourceSans,
        ["SourceSans Bold"] = Enum.Font.SourceSansBold,
        ["Gotham"] = Enum.Font.Gotham,
        ["Gotham Bold"] = Enum.Font.GothamBold,
        ["Minecraft"] = Enum.Font.Minecraft,
        ["Cartoon"] = Enum.Font.Cartoon,
    },
}

local MatAttr = ("ESP_Mat_%d"):format(math.random(100000, 999999))

local function GetBodyParts(char)
    local out = {}
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            out[#out+1] = p
        end
    end
    return out
end

local function ComputeBounds(model)
    local min = Vector3.new(math.huge, math.huge, math.huge)
    local max = Vector3.new(-math.huge, -math.huge, -math.huge)
    local verts = {
        Vector3.new(-0.5,-0.5,-0.5), Vector3.new(-0.5,0.5,-0.5),
        Vector3.new(0.5,-0.5,-0.5), Vector3.new(0.5,0.5,-0.5),
        Vector3.new(-0.5,-0.5,0.5), Vector3.new(-0.5,0.5,0.5),
        Vector3.new(0.5,-0.5,0.5), Vector3.new(0.5,0.5,0.5),
    }
    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            local cf, sz = part.CFrame, part.Size
            for _, v in ipairs(verts) do
                local ws = cf:PointToWorldSpace(v * sz)
                local ws2 = cf:PointToWorldSpace(Vector3.new(v.X*sz.X, (v.Y+0.15)*(sz.Y+0.15), v.Z*sz.Z))
                min = Vector3.new(math.min(min.X, ws2.X), math.min(min.Y, ws2.Y), math.min(min.Z, ws2.Z))
                max = Vector3.new(math.max(max.X, ws.X), math.max(max.Y, ws.Y), math.max(max.Z, ws.Z))
            end
        end
    end
    if min == Vector3.new(math.huge, math.huge, math.huge) then return end
    return (min+max)/2, max-min
end

function ESP:DestroyPlayer(plr)
    local c = ESP.Cache[plr]
    if not c then return end
    if c.BoxGui then c.BoxGui:Destroy() end
    if c.NameGui then c.NameGui:Destroy() end
    if c.DistGui then c.DistGui:Destroy() end
    if c.WeapGui then c.WeapGui:Destroy() end
    if c.HpGui then c.HpGui:Destroy() end
    if c.ArmGui then c.ArmGui:Destroy() end
    if c.Highlight then c.Highlight:Destroy() end
    if c.Chams then for _, v in ipairs(c.Chams) do v:Destroy() end end
    if c.CharConn then c.CharConn:Disconnect() end
    ESP.Cache[plr] = nil
end

function ESP:ClearCache()
    for plr in pairs(ESP.Cache) do
        ESP:DestroyPlayer(plr)
    end
    ESP.Cache = {}
end

function ESP:CreateScreenGui(name)
    local g = Instance.new("ScreenGui")
    g.Name = name
    g.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    g.Parent = CoreGui
    return g
end

function ESP:MakeLabel(parent)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.TextColor3 = Color3.new(1,1,1)
    l.TextStrokeTransparency = 0
    l.TextStrokeColor3 = Color3.new(0,0,0)
    l.TextScaled = false
    l.TextSize = ESP.Config.TextSize
    l.FontFace = ESP.Fonts[ESP.Config.Font]
    l.Text = ""
    l.Visible = false
    l.Parent = parent
    return l
end

function ESP:CreateBox(plr)
    local gui = ESP:CreateScreenGui("ESP_Box_"..plr.Name)
    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Parent = gui
    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = ESP.Config.Box.Color
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = box
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = ESP.Config.Box.FillColor
    fill.BackgroundTransparency = ESP.Config.Box.FillTrans
    fill.BorderSizePixel = 0
    fill.Visible = false
    fill.Parent = gui
    fill.ZIndex = -1
    return gui, box, stroke, fill
end

function ESP:CreateBar(plr, name, color)
    local gui = ESP:CreateScreenGui("ESP_"..name.."_"..plr.Name)
    local outline = Instance.new("Frame")
    outline.Name = "Outline"
    outline.BackgroundColor3 = Color3.new(0,0,0)
    outline.BorderSizePixel = 0
    outline.Parent = gui
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.Parent = outline
    return gui, outline, fill
end

function ESP:ApplyMaterialOver(plr, char)
    if not char then return end
    if not plr:HasAppearanceLoaded() then plr.CharacterAppearanceLoaded:Wait() end
    task.wait(0.2)
    local mat = ESP.Config.Material.Type
    local col = ESP.Config.Material.Color
    for _, part in ipairs(GetBodyParts(char)) do
        part.Material = mat
        part.Color = col
        if part.Transparency ~= 1 then part.Transparency = 0.5 end
    end
    for _, acc in ipairs(char:GetDescendants()) do
        if acc.ClassName == "Accessory" then
            local h = acc:FindFirstChild("Handle")
            if h and h:IsA("MeshPart") then
                if not h:GetAttribute(MatAttr) then h:SetAttribute(MatAttr, h.TextureID) end
                h.Material = mat; h.TextureID = ""; h.Color = col
            end
        end
    end
    local function strip(obj, attr, prop)
        if obj and obj[prop] ~= "" then obj:SetAttribute(attr, obj[prop]); obj[prop] = "" end
    end
    strip(char:FindFirstChildOfClass("Shirt"), "_OrigShirt", "ShirtTemplate")
    strip(char:FindFirstChildOfClass("Pants"), "_OrigPants", "PantsTemplate")
    strip(char:FindFirstChildOfClass("ShirtGraphic"), "_OrigGraphic", "Graphic")
end

function ESP:RevertMaterial(plr, char)
    if not char then return end
    for _, part in ipairs(GetBodyParts(char)) do
        part.Material = Enum.Material.SmoothPlastic
        if part.Transparency ~= 1 then part.Transparency = 0 end
    end
    for _, acc in ipairs(char:GetDescendants()) do
        if acc.ClassName == "Accessory" then
            local h = acc:FindFirstChild("Handle")
            if h and h:IsA("MeshPart") then
                local orig = h:GetAttribute(MatAttr)
                if orig then h.TextureID = orig; h:SetAttribute(MatAttr, nil) end
                h.Material = Enum.Material.SmoothPlastic; h.Transparency = 0
            end
        end
    end
    local function restore(obj, attr, prop)
        if obj then local o = obj:GetAttribute(attr); if o then obj[prop] = o; obj:SetAttribute(attr, nil) end end
    end
    restore(char:FindFirstChildOfClass("Shirt"), "_OrigShirt", "ShirtTemplate")
    restore(char:FindFirstChildOfClass("Pants"), "_OrigPants", "PantsTemplate")
    restore(char:FindFirstChildOfClass("ShirtGraphic"), "_OrigGraphic", "Graphic")
end

function ESP:AddPlayer(plr)
    if plr == Players.LocalPlayer then return end
    local c = {}
    local g, bx, st, fl = ESP:CreateBox(plr)
    c.BoxGui = g; c.Box = bx; c.Stroke = st; c.Fill = fl
    local ng = ESP:CreateScreenGui("ESP_Name_"..plr.Name)
    c.NameGui = ng; c.NameLbl = ESP:MakeLabel(ng)
    local dg = ESP:CreateScreenGui("ESP_Dist_"..plr.Name)
    c.DistGui = dg; c.DistLbl = ESP:MakeLabel(dg)
    local wg = ESP:CreateScreenGui("ESP_Weap_"..plr.Name)
    c.WeapGui = wg; c.WeapLbl = ESP:MakeLabel(wg)
    local hg, ho, hf = ESP:CreateBar(plr, "Health", ESP.Config.HealthBar.Color)
    c.HpGui = hg; c.HpOut = ho; c.HpFill = hf
    local ag, ao, af = ESP:CreateBar(plr, "Armor", ESP.Config.ArmorBar.Color)
    c.ArmGui = ag; c.ArmOut = ao; c.ArmFill = af
    c.CharConn = plr.CharacterAdded:Connect(function(nc)
        c.Character = nc
        if ESP.Config.Highlight.Enabled then ESP:AddHighlight(plr, nc) end
        if ESP.Config.Chams.Enabled then ESP:AddChams(plr, nc) end
        if ESP.Config.Material.Enabled then task.spawn(ESP.ApplyMaterialOver, ESP, plr, nc) end
    end)
    ESP.Cache[plr] = c
    if plr.Character then
        if ESP.Config.Highlight.Enabled then ESP:AddHighlight(plr, plr.Character) end
        if ESP.Config.Chams.Enabled then ESP:AddChams(plr, plr.Character) end
        if ESP.Config.Material.Enabled then task.spawn(ESP.ApplyMaterialOver, ESP, plr, plr.Character) end
    end
end

function ESP:AddHighlight(plr, char)
    ESP:RemoveHighlight(plr)
    local h = Instance.new("Highlight")
    h.FillColor = ESP.Config.Highlight.Color
    h.OutlineColor = ESP.Config.Highlight.Outline
    h.DepthMode = ESP.Config.Highlight.BehindWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    h.Adornee = char
    h.Parent = CoreGui
    if ESP.Cache[plr] then ESP.Cache[plr].Highlight = h end
end

function ESP:RemoveHighlight(plr)
    local c = ESP.Cache[plr]
    if c and c.Highlight then c.Highlight:Destroy(); c.Highlight = nil end
end

function ESP:AddChams(plr, char)
    ESP:RemoveChams(plr)
    local list = {}
    local z = ESP.Config.Chams.BehindWalls and 1 or -1
    for _, part in ipairs(GetBodyParts(char)) do
        local b = Instance.new("BoxHandleAdornment")
        b.Adornee = part; b.Color3 = ESP.Config.Chams.Color
        b.ZIndex = z; b.AlwaysOnTop = ESP.Config.Chams.BehindWalls
        b.Size = part.Size + Vector3.new(0.02,0.02,0.02); b.Transparency = 0.5
        b.Parent = CoreGui; list[#list+1] = b
    end
    if ESP.Cache[plr] then ESP.Cache[plr].Chams = list end
end

function ESP:RemoveChams(plr)
    local c = ESP.Cache[plr]
    if c and c.Chams then
        for _, v in ipairs(c.Chams) do v:Destroy() end
        c.Chams = nil
    end
end

function ESP:UpdateBox(plr, pos, size, inset)
    local c = ESP.Cache[plr]
    if not c then return end
    local cfg = ESP.Config.Box
    if cfg.Enabled then
        c.Box.Visible = true
        c.Box.Position = UDim2.fromOffset(pos.X, pos.Y-inset)
        c.Box.Size = UDim2.fromOffset(size.X, size.Y)
        c.Stroke.Color = cfg.Color
        c.Fill.Visible = cfg.Filled
        c.Fill.BackgroundColor3 = cfg.FillColor
        c.Fill.BackgroundTransparency = cfg.FillTrans
        c.Fill.Position = c.Box.Position
        c.Fill.Size = c.Box.Size
    else
        c.Box.Visible = false; c.Fill.Visible = false
    end
end

function ESP:UpdateName(plr, x, y, inset)
    local c = ESP.Cache[plr]
    if not c then return end
    local cfg = ESP.Config.Name
    if cfg.Enabled then
        c.NameLbl.Visible = true
        c.NameLbl.Text = (cfg.Mode == "DisplayName" and plr.DisplayName or plr.Name):lower()
        c.NameLbl.TextColor3 = cfg.Color
        c.NameLbl.FontFace = ESP.Fonts[ESP.Config.Font]
        c.NameLbl.TextSize = ESP.Config.TextSize
        c.NameLbl.Position = UDim2.fromOffset(x - c.NameLbl.TextBounds.X/2, y-18-inset)
    else
        c.NameLbl.Visible = false
    end
end

function ESP:UpdateDistance(plr, x, y, inset, dist)
    local c = ESP.Cache[plr]
    if not c then return end
    local cfg = ESP.Config.Distance
    if cfg.Enabled then
        c.DistLbl.Visible = true
        c.DistLbl.Text = ("[%d]"):format(math.floor(dist * 0.28))
        c.DistLbl.TextColor3 = cfg.Color
        c.DistLbl.FontFace = ESP.Fonts[ESP.Config.Font]
        c.DistLbl.TextSize = ESP.Config.TextSize
        c.DistLbl.Position = UDim2.fromOffset(x - c.DistLbl.TextBounds.X/2, y+ESP.Cache[plr].Box.Size.Y.Offset+2-inset)
    else
        c.DistLbl.Visible = false
    end
end

function ESP:UpdateWeapon(plr, x, y, inset, scaleY)
    local c = ESP.Cache[plr]
    if not c then return end
    local cfg = ESP.Config.Weapon
    if cfg.Enabled then
        c.WeapLbl.Visible = true
        local tool = (plr.Character and plr.Character:FindFirstChildOfClass("Tool"))
        c.WeapLbl.Text = (tool and tool.Name or "None"):lower()
        c.WeapLbl.TextColor3 = cfg.Color
        c.WeapLbl.FontFace = ESP.Fonts[ESP.Config.Font]
        c.WeapLbl.TextSize = ESP.Config.TextSize
        c.WeapLbl.Position = UDim2.fromOffset(x - c.WeapLbl.TextBounds.X/2, y+scaleY+2-inset)
    else
        c.WeapLbl.Visible = false
    end
end

function ESP:UpdateHpBar(plr, y, scaleY, inset)
    local c = ESP.Cache[plr]
    if not c then return end
    local cfg = ESP.Config.HealthBar
    local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
    local bh = scaleY; local bw = 2
    local bx = c.Box.Position.X.Offset - 6
    local by = c.Box.Position.Y.Offset
    if cfg.Enabled and hum then
        local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        local h = bh * pct
        c.HpOut.Visible = true
        c.HpOut.Position = UDim2.fromOffset(bx-1, by-1)
        c.HpOut.Size = UDim2.fromOffset(bw+2, bh+2)
        c.HpFill.Visible = true
        c.HpFill.Position = UDim2.fromOffset(1, 1+(bh-h))
        c.HpFill.Size = UDim2.fromOffset(bw, h)
        c.HpFill.BackgroundColor3 = cfg.Color:Lerp(Color3.new(1,0,0), 1-pct)
    else
        if c.HpOut then c.HpOut.Visible = false; c.HpFill.Visible = false end
    end
end

function ESP:UpdateArmorBar(plr, y, scaleY, inset)
    local c = ESP.Cache[plr]
    if not c then return end
    local cfg = ESP.Config.ArmorBar
    local char = plr.Character
    local bh = scaleY
    local bw = 2
    local bx = c.Box.Position.X.Offset - 6
    local by = c.Box.Position.Y.Offset
    if cfg.Enabled and char then
        local be = char:FindFirstChild("BodyEffects")
        local av = be and be:FindFirstChild("Armor")
        local val = av and av.Value or 0
        local pct = math.clamp(val/130, 0, 1)
        local h = bh * pct
        local ax = bx - 6
        c.ArmOut.Visible = true
        c.ArmOut.Position = UDim2.fromOffset(ax-1, by-1)
        c.ArmOut.Size = UDim2.fromOffset(bw+2, bh+2)
        c.ArmFill.Visible = true
        c.ArmFill.Position = UDim2.fromOffset(1, 1+(bh-h))
        c.ArmFill.Size = UDim2.fromOffset(bw, h)
        c.ArmFill.BackgroundColor3 = cfg.Color
    else
        if c.ArmOut then c.ArmOut.Visible = false; c.ArmFill.Visible = false end
    end
end

function ESP:Update()
    if not ESP.Enabled then return end
    local cam = workspace.CurrentCamera
    if not cam then return end
    for plr, c in pairs(ESP.Cache) do
        if not plr then continue end
        local char = plr.Character
        if not char then continue end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp then continue end
        local center, size3 = ComputeBounds(char)
        if not center then continue end
        local sp, onScr = cam:WorldToViewportPoint(center)
        if not onScr then
            c.Box.Visible = false; c.Fill.Visible = false
            c.NameLbl.Visible = false; c.DistLbl.Visible = false; c.WeapLbl.Visible = false
            c.HpOut.Visible = false; c.HpFill.Visible = false
            c.ArmOut.Visible = false; c.ArmFill.Visible = false
            continue
        end
        local dist = (cam.CFrame.Position - center).Magnitude
        local h = math.tan(math.rad(cam.FieldOfView/2)) * 2 * dist
        local scale = Vector2.new(cam.ViewportSize.Y/h * size3.X, cam.ViewportSize.Y/h * size3.Y)
        local pos = Vector2.new(sp.X - scale.X/2, sp.Y - scale.Y/2)
        local inset = GuiService:GetGuiInset().Y
        -- Highlight
        if ESP.Config.Highlight.Enabled then
            if not c.Highlight then ESP:AddHighlight(plr, char) end
            if c.Highlight then
                c.Highlight.FillColor = ESP.Config.Highlight.Color
                c.Highlight.OutlineColor = ESP.Config.Highlight.Outline
                c.Highlight.DepthMode = ESP.Config.Highlight.BehindWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
            end
        else ESP:RemoveHighlight(plr) end
        -- Chams
        if ESP.Config.Chams.Enabled then
            if not c.Chams then ESP:AddChams(plr, char) end
            local z = ESP.Config.Chams.BehindWalls and 1 or -1
            for _, v in ipairs(c.Chams or {}) do v.Color3 = ESP.Config.Chams.Color; v.ZIndex = z; v.AlwaysOnTop = ESP.Config.Chams.BehindWalls end
        else ESP:RemoveChams(plr) end
        -- Material
        if ESP.Config.Material.Enabled and not c.MatApplied then
            task.spawn(ESP.ApplyMaterialOver, ESP, plr, char); c.MatApplied = true
        elseif not ESP.Config.Material.Enabled and c.MatApplied then
            ESP:RevertMaterial(plr, char); c.MatApplied = false
        end
        -- UI elements
        ESP:UpdateBox(plr, pos, scale, inset)
        local cx = pos.X + scale.X/2
        local cy = pos.Y
        ESP:UpdateName(plr, cx, cy, 0)
        ESP:UpdateDistance(plr, cx, cy, 0, dist)
        ESP:UpdateWeapon(plr, cx, cy, 0, scale.Y)
        ESP:UpdateHpBar(plr, cy, scale.Y, 0)
        ESP:UpdateArmorBar(plr, cy, scale.Y, 0)
    end
end

function ESP:BuildUI(tab)
    local L = tab:AddLeftGroupbox("Player ESP")
    local R = tab:AddRightGroupbox("Text & Bars")

    local b = L:AddToggle("ESP_Box", { Text = "Box", Default = false, Callback = function(v) ESP.Config.Box.Enabled = v end })
    b:AddColorPicker("BoxColor", { Default = ESP.Config.Box.Color, Callback = function(v) ESP.Config.Box.Color = v end })
    local f = L:AddToggle("ESP_Filled", { Text = "Filled Box", Default = false, Callback = function(v) ESP.Config.Box.Filled = v end })
    f:AddColorPicker("FillColor", { Default = ESP.Config.Box.FillColor, Callback = function(v) ESP.Config.Box.FillColor = v end })
    f:AddSlider("FillTrans", { Text = "Fill Transparency", Default = 0.5, Min = 0, Max = 1, Rounding = 2, Callback = function(v) ESP.Config.Box.FillTrans = v end })

    local hl = L:AddToggle("ESP_Highlight", { Text = "Highlight", Default = false, Callback = function(v)
        ESP.Config.Highlight.Enabled = v
        if not v then for p in pairs(ESP.Cache) do ESP:RemoveHighlight(p) end end
    end })
    hl:AddColorPicker("HLFill", { Default = ESP.Config.Highlight.Color, Callback = function(v) ESP.Config.Highlight.Color = v end })
    hl:AddColorPicker("HLOutline", { Default = ESP.Config.Highlight.Outline, Callback = function(v) ESP.Config.Highlight.Outline = v end })
    L:AddToggle("HL_Walls", { Text = "Behind Walls", Default = false, Callback = function(v) ESP.Config.Highlight.BehindWalls = v end })

    local ch = L:AddToggle("ESP_Chams", { Text = "Chams", Default = false, Callback = function(v)
        ESP.Config.Chams.Enabled = v
        if not v then for p in pairs(ESP.Cache) do ESP:RemoveChams(p) end end
    end })
    ch:AddColorPicker("ChamsColor", { Default = ESP.Config.Chams.Color, Callback = function(v) ESP.Config.Chams.Color = v end })
    L:AddToggle("Chams_Walls", { Text = "Chams Behind Walls", Default = false, Callback = function(v) ESP.Config.Chams.BehindWalls = v end })
    L:AddDivider()

    local mat = L:AddToggle("ESP_Material", { Text = "Material Override", Default = false, Callback = function(v)
        ESP.Config.Material.Enabled = v
        if not v then for p, c in pairs(ESP.Cache) do if c.MatApplied then ESP:RevertMaterial(p, c.Character); c.MatApplied = false end end end
    end })
    mat:AddColorPicker("MatColor", { Default = ESP.Config.Material.Color, Callback = function(v) ESP.Config.Material.Color = v end })
    L:AddDropdown("MatType", { Values = {"ForceField","Neon","Glass","SmoothPlastic"}, Default = "ForceField", Text = "Material", Callback = function(v) ESP.Config.Material.Type = Enum.Material[v] end })

    local nt = R:AddToggle("ESP_Name", { Text = "Name", Default = false, Callback = function(v) ESP.Config.Name.Enabled = v end })
    nt:AddColorPicker("NameColor", { Default = ESP.Config.Name.Color, Callback = function(v) ESP.Config.Name.Color = v end })
    R:AddDropdown("NameMode", { Values = {"DisplayName","Username"}, Default = "DisplayName", Text = "Type", Callback = function(v) ESP.Config.Name.Mode = v end })
    local wt = R:AddToggle("ESP_Weapon", { Text = "Weapon", Default = false, Callback = function(v) ESP.Config.Weapon.Enabled = v end })
    wt:AddColorPicker("WepColor", { Default = ESP.Config.Weapon.Color, Callback = function(v) ESP.Config.Weapon.Color = v end })
    local dt = R:AddToggle("ESP_Dist", { Text = "Distance", Default = false, Callback = function(v) ESP.Config.Distance.Enabled = v end })
    dt:AddColorPicker("DistColor", { Default = ESP.Config.Distance.Color, Callback = function(v) ESP.Config.Distance.Color = v end })
    R:AddDropdown("ESPFont", { Values = {"SourceSans","SourceSans Bold","Gotham","Gotham Bold","Minecraft","Cartoon"}, Default = "SourceSans Bold", Text = "Font", Callback = function(v) ESP.Config.Font = v end })
    R:AddSlider("TextSize", { Text = "Text Size", Default = 12, Min = 8, Max = 20, Rounding = 0, Callback = function(v) ESP.Config.TextSize = v end })
    R:AddDivider()

    local hb = R:AddToggle("ESP_HpBar", { Text = "Health Bar", Default = false, Callback = function(v) ESP.Config.HealthBar.Enabled = v end })
    hb:AddColorPicker("HpColor", { Default = ESP.Config.HealthBar.Color, Callback = function(v) ESP.Config.HealthBar.Color = v end })
    local ab = R:AddToggle("ESP_ArmorBar", { Text = "Armor Bar", Default = false, Callback = function(v) ESP.Config.ArmorBar.Enabled = v end })
    ab:AddColorPicker("ArmorColor", { Default = ESP.Config.ArmorBar.Color, Callback = function(v) ESP.Config.ArmorBar.Color = v end })
    R:AddDivider()

    local mt = R:AddToggle("ESP_Enabled", { Text = "Enable ESP", Default = false, Callback = function(v)
        ESP.Enabled = v
        if v then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= Players.LocalPlayer then ESP:AddPlayer(p) end
            end
        else
            ESP:ClearCache()
        end
    end })
    mt:AddKeyPicker("ESP_Keybind", { Text = "Toggle", Default = "None", Mode = "Toggle", SyncToggleState = true, Callback = function(v)
        ESP.Enabled = v
        if v then
            for _, p in ipairs(Players:GetPlayers()) do if p ~= Players.LocalPlayer then ESP:AddPlayer(p) end end
        else
            ESP:ClearCache()
        end
    end })
end

function ESP:Initialize(tab)
    ESP:BuildUI(tab)
    ESP.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(p)
        if p ~= Players.LocalPlayer and ESP.Enabled then ESP:AddPlayer(p) end
    end)
    ESP.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(p)
        if p ~= Players.LocalPlayer then ESP:DestroyPlayer(p) end
    end)
    ESP.Connections.Render = RunService.RenderStepped:Connect(function()
        ESP:Update()
    end)
    return ESP
end

function ESP:Cleanup()
    ESP.Enabled = false
    for _, c in pairs(ESP.Connections) do
        if c then pcall(c.Disconnect, c) end
    end
    ESP.Connections = {}
    ESP:ClearCache()
end

return ESP