local ESP = {}
ESP.__index = ESP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")

local function GetCase(text, caseType)
    caseType = caseType or "lowercase"
    if caseType == "UPPERCASE" then return text:upper() end
    if caseType == "lowercase" then return text:lower() end
    return text
end

local function GetBodyParts(char)
    local parts = {}
    for _, p in ipairs(char:GetChildren()) do
        if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
            parts[#parts + 1] = p
        end
    end
    return parts
end

local function CustomBounds(model)
    local minB = Vector3.new(math.huge, math.huge, math.huge)
    local maxB = Vector3.new(-math.huge, -math.huge, -math.huge)
    local verts = {
        Vector3.new(-0.5, -0.5, -0.5), Vector3.new(-0.5, 0.5, -0.5),
        Vector3.new(0.5, -0.5, -0.5), Vector3.new(0.5, 0.5, -0.5),
        Vector3.new(-0.5, -0.5, 0.5), Vector3.new(-0.5, 0.5, 0.5),
        Vector3.new(0.5, -0.5, 0.5), Vector3.new(0.5, 0.5, 0.5),
    }
    local inc = Vector3.new(2, 2, 2)
    for _, part in ipairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            local cf, sz = part.CFrame, part.Size
            for _, v in ipairs(verts) do
                local ws = cf:PointToWorldSpace(Vector3.new(v.X * sz.X, (v.Y + 0.2) * (sz.Y + 0.2), v.Z * sz.Z))
                minB = Vector3.new(math.min(minB.X, ws.X), math.min(minB.Y, ws.Y), math.min(minB.Z, ws.Z))
                maxB = Vector3.new(math.max(maxB.X, ws.X), math.max(maxB.Y, ws.Y), math.max(maxB.Z, ws.Z))
            end
        end
    end
    if minB == Vector3.new(math.huge, math.huge, math.huge) then return end
    local center = (minB + maxB) / 2
    return CFrame.new(center), maxB - minB + inc, center
end

local Fonts = {
    ["SourceSans"] = Enum.Font.SourceSans,
    ["SourceSans Bold"] = Enum.Font.SourceSansBold,
    ["Gotham"] = Enum.Font.Gotham,
    ["Gotham Bold"] = Enum.Font.GothamBold,
    ["Minecraft"] = Enum.Font.Minecraft,
    ["Cartoon"] = Enum.Font.Cartoon,
}

local MatAttr = "ESP_Mat_" .. math.random(100000, 999999)

local function DefaultConfig()
    return {
        Enabled = false,
        Box = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Filled = false, FillColor = Color3.fromRGB(255, 255, 255), FillTransparency = 0.5 },
        HealthBar = { Enabled = false, Color = Color3.fromRGB(0, 255, 0) },
        ArmorBar = { Enabled = false, Color = Color3.fromRGB(0, 0, 255) },
        Name = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Mode = "DisplayName" },
        Distance = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) },
        Weapon = { Enabled = false, Color = Color3.fromRGB(255, 255, 255) },
        Highlight = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Outline = Color3.fromRGB(0, 0, 0), BehindWalls = false },
        Chams = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), BehindWalls = false },
        Material = { Enabled = false, Color = Color3.fromRGB(255, 255, 255), Type = Enum.Material.ForceField },
        Font = "SourceSans Bold",
        TextSize = 12,
    }
end

function ESP:Initialize(tab)
    local self = setmetatable({}, ESP)
    self.cfg = DefaultConfig()
    self.cache = {}
    self.conns = {}
    self:BuildUI(tab)
    self:Hook()
    return self
end

function ESP:MakeText()
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.TextColor3 = Color3.new(1, 1, 1)
    lbl.TextStrokeTransparency = 0
    lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
    lbl.TextScaled = false
    lbl.TextSize = self.cfg.TextSize
    lbl.FontFace = Fonts[self.cfg.Font]
    lbl.Text = ""
    lbl.Visible = false
    return lbl
end

function ESP:CreateBoxGui(plr)
    local gui = Instance.new("ScreenGui")
    gui.Name = "ESP_Box_" .. plr.Name
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = CoreGui

    local box = Instance.new("Frame")
    box.Name = "Box"
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    box.Parent = gui

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 2
    stroke.Color = self.cfg.Box.Color
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = box

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = self.cfg.Box.FillColor
    fill.BackgroundTransparency = self.cfg.Box.FillTransparency
    fill.BorderSizePixel = 0
    fill.Visible = false
    fill.Parent = gui
    fill.ZIndex = -1

    return { Gui = gui, Box = box, Stroke = stroke, Fill = fill }
end

function ESP:CreateBarGui(plr, name, color)
    local gui = Instance.new("ScreenGui")
    gui.Name = "ESP_" .. name .. "_" .. plr.Name
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = CoreGui

    local outline = Instance.new("Frame")
    outline.Name = "Outline"
    outline.BackgroundColor3 = Color3.new(0, 0, 0)
    outline.BorderSizePixel = 0
    outline.Parent = gui

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.Parent = outline

    return { Gui = gui, Outline = outline, Fill = fill }
end

function ESP:CreateHighlight(plr, char)
    self:RemoveHighlight(plr)
    local h = Instance.new("Highlight")
    h.FillColor = self.cfg.Highlight.Color
    h.OutlineColor = self.cfg.Highlight.Outline
    h.DepthMode = self.cfg.Highlight.BehindWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded
    h.Adornee = char
    h.Parent = CoreGui
    self.cache[plr].Highlight = h
end

function ESP:RemoveHighlight(plr)
    local h = self.cache[plr] and self.cache[plr].Highlight
    if h then h:Destroy() self.cache[plr].Highlight = nil end
end

function ESP:CreateChams(plr, char)
    self:RemoveChams(plr)
    local list = {}
    local z = self.cfg.Chams.BehindWalls and 1 or -1
    for _, part in ipairs(GetBodyParts(char)) do
        local box = Instance.new("BoxHandleAdornment")
        box.Adornee = part
        box.Color3 = self.cfg.Chams.Color
        box.ZIndex = z
        box.AlwaysOnTop = self.cfg.Chams.BehindWalls
        box.Size = part.Size + Vector3.new(0.02, 0.02, 0.02)
        box.Transparency = 0.5
        box.Parent = CoreGui
        list[#list + 1] = box
    end
    self.cache[plr].Chams = list
end

function ESP:RemoveChams(plr)
    local list = self.cache[plr] and self.cache[plr].Chams
    if list then for _, v in ipairs(list) do v:Destroy() end self.cache[plr].Chams = nil end
end

function ESP:ApplyMaterial(plr, char)
    if not char then return end
    if not plr:HasAppearanceLoaded() then plr.CharacterAppearanceLoaded:Wait() end
    task.wait(0.2)
    local mat = self.cfg.Material.Type
    local col = self.cfg.Material.Color
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
                h.Material = mat
                h.TextureID = ""
                h.Color = col
            end
        end
    end
    local function strip(obj, attr, prop)
        if obj and obj[prop] ~= "" then obj:SetAttribute(attr, obj[prop]) obj[prop] = "" end
    end
    strip(char:FindFirstChildOfClass("Shirt"), "_OrigShirt", "ShirtTemplate")
    strip(char:FindFirstChildOfClass("Pants"), "_OrigPants", "PantsTemplate")
    strip(char:FindFirstChildOfClass("ShirtGraphic"), "_OrigGraphic", "Graphic")
end

function ESP:RemoveMaterial(plr, char)
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
                if orig then h.TextureID = orig h:SetAttribute(MatAttr, nil) end
                h.Material = Enum.Material.SmoothPlastic
                h.Transparency = 0
            end
        end
    end
    local function restore(obj, attr, prop)
        if obj then local o = obj:GetAttribute(attr) if o then obj[prop] = o obj:SetAttribute(attr, nil) end end
    end
    restore(char:FindFirstChildOfClass("Shirt"), "_OrigShirt", "ShirtTemplate")
    restore(char:FindFirstChildOfClass("Pants"), "_OrigPants", "PantsTemplate")
    restore(char:FindFirstChildOfClass("ShirtGraphic"), "_OrigGraphic", "Graphic")
end

function ESP:SetupPlayer(plr)
    if plr == Players.LocalPlayer then return end
    local c = self.cache[plr] or {}
    c.Box = self:CreateBoxGui(plr)
    c.NameLbl = self:MakeText()
    c.DistLbl = self:MakeText()
    c.WeapLbl = self:MakeText()
    c.HealthBar = self:CreateBarGui(plr, "Health", self.cfg.HealthBar.Color)
    c.ArmorBar = self:CreateBarGui(plr, "Armor", self.cfg.ArmorBar.Color)
    c.CharAdded = plr.CharacterAdded:Connect(function(nc)
        c.Character = nc
        if self.cfg.Highlight.Enabled then self:CreateHighlight(plr, nc) end
        if self.cfg.Chams.Enabled then self:CreateChams(plr, nc) end
        if self.cfg.Material.Enabled then task.spawn(self.ApplyMaterial, self, plr, nc) end
    end)
    self.cache[plr] = c

    if plr.Character then
        if self.cfg.Highlight.Enabled then self:CreateHighlight(plr, plr.Character) end
        if self.cfg.Chams.Enabled then self:CreateChams(plr, plr.Character) end
        if self.cfg.Material.Enabled then task.spawn(self.ApplyMaterial, self, plr, plr.Character) end
    end
end

function ESP:CleanupPlayer(plr)
    local c = self.cache[plr]
    if not c then return end
    if c.Box then c.Box.Gui:Destroy() end
    for _, k in ipairs({"NameLbl", "DistLbl", "WeapLbl"}) do
        if c[k] and c[k].Parent then c[k].Parent:Destroy() end
    end
    for _, k in ipairs({"HealthBar", "ArmorBar"}) do
        if c[k] and c[k].Gui then c[k].Gui:Destroy() end
    end
    self:RemoveHighlight(plr)
    self:RemoveChams(plr)
    self:RemoveMaterial(plr, c.Character)
    if c.CharAdded then c.CharAdded:Disconnect() end
    self.cache[plr] = nil
end

function ESP:CleanupAll()
    for plr in pairs(self.cache) do self:CleanupPlayer(plr) end
    self.cache = {}
end

function ESP:UpdatePlayer(plr)
    local c = self.cache[plr]
    if not c then return end
    local char = plr.Character
    local cam = workspace.CurrentCamera
    if not char or not cam then self:CleanupPlayer(plr) return end

    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then self:CleanupPlayer(plr) return end

    local cf, size3, center = CustomBounds(char)
    if not cf then self:CleanupPlayer(plr) return end

    local sp, onScr = cam:WorldToViewportPoint(center)
    if not onScr then self:CleanupPlayer(plr) return end

    local dist = (cam.CFrame.Position - center).Magnitude
    local h = math.tan(math.rad(cam.FieldOfView / 2)) * 2 * dist
    local scale = Vector2.new((cam.ViewportSize.Y / h) * size3.X, (cam.ViewportSize.Y / h) * size3.Y)
    local pos = Vector2.new(sp.X - scale.X / 2, sp.Y - scale.Y / 2)
    local guiInset = GuiService:GetGuiInset().Y

    -- Highlight
    if self.cfg.Highlight.Enabled then
        if not c.Highlight then self:CreateHighlight(plr, char) end
        local h = c.Highlight
        if h then h.FillColor = self.cfg.Highlight.Color h.OutlineColor = self.cfg.Highlight.Outline
            h.DepthMode = self.cfg.Highlight.BehindWalls and Enum.HighlightDepthMode.AlwaysOnTop or Enum.HighlightDepthMode.Occluded end
    else
        self:RemoveHighlight(plr)
    end

    -- Chams
    if self.cfg.Chams.Enabled then
        if not c.Chams then self:CreateChams(plr, char) end
        local z = self.cfg.Chams.BehindWalls and 1 or -1
        for _, v in ipairs(c.Chams or {}) do v.Color3 = self.cfg.Chams.Color v.ZIndex = z v.AlwaysOnTop = self.cfg.Chams.BehindWalls end
    else
        self:RemoveChams(plr)
    end

    -- Material
    if self.cfg.Material.Enabled and not c.MatApplied then
        task.spawn(self.ApplyMaterial, self, plr, char)
        c.MatApplied = true
    elseif not self.cfg.Material.Enabled and c.MatApplied then
        self:RemoveMaterial(plr, char)
        c.MatApplied = false
    end

    -- Box
    if self.cfg.Box.Enabled and c.Box then
        local b = c.Box
        b.Box.Visible = true
        b.Box.Position = UDim2.fromOffset(pos.X, pos.Y - guiInset)
        b.Box.Size = UDim2.fromOffset(scale.X, scale.Y)
        b.Stroke.Color = self.cfg.Box.Color
        b.Fill.Visible = self.cfg.Box.Filled
        b.Fill.BackgroundColor3 = self.cfg.Box.FillColor
        b.Fill.BackgroundTransparency = self.cfg.Box.FillTransparency
        b.Fill.Position = b.Box.Position
        b.Fill.Size = b.Box.Size
    elseif c.Box then
        c.Box.Box.Visible = false
        c.Box.Fill.Visible = false
    end

    -- Health Bar
    local bh = scale.Y
    local bw = 2
    local bx = pos.X - 6
    local by = pos.Y - guiInset

    if self.cfg.HealthBar.Enabled and hum then
        local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
        local h = bh * pct
        local hb = c.HealthBar
        hb.Outline.Visible = true
        hb.Outline.Position = UDim2.fromOffset(bx - 1, by - 1)
        hb.Outline.Size = UDim2.fromOffset(bw + 2, bh + 2)
        hb.Fill.Visible = true
        hb.Fill.Position = UDim2.fromOffset(1, 1 + (bh - h))
        hb.Fill.Size = UDim2.fromOffset(bw, h)
        hb.Fill.BackgroundColor3 = self.cfg.HealthBar.Color:Lerp(Color3.new(1, 0, 0), 1 - pct)
    else
        if c.HealthBar then c.HealthBar.Outline.Visible = false c.HealthBar.Fill.Visible = false end
    end

    -- Armor Bar
    if self.cfg.ArmorBar.Enabled and char then
        local be = char:FindFirstChild("BodyEffects")
        local av = be and be:FindFirstChild("Armor")
        local val = av and av.Value or 0
        local pct = math.clamp(val / 130, 0, 1)
        local h = bh * pct
        local ax = bx - 6
        local ab = c.ArmorBar
        ab.Outline.Visible = true
        ab.Outline.Position = UDim2.fromOffset(ax - 1, by - 1)
        ab.Outline.Size = UDim2.fromOffset(bw + 2, bh + 2)
        ab.Fill.Visible = true
        ab.Fill.Position = UDim2.fromOffset(1, 1 + (bh - h))
        ab.Fill.Size = UDim2.fromOffset(bw, h)
        ab.Fill.BackgroundColor3 = self.cfg.ArmorBar.Color
    else
        if c.ArmorBar then c.ArmorBar.Outline.Visible = false c.ArmorBar.Fill.Visible = false end
    end

    -- Text
    local tx = pos.X + scale.X / 2
    local ty = pos.Y - guiInset

    if self.cfg.Name.Enabled then
        c.NameLbl.Visible = true
        c.NameLbl.Text = GetCase(self.cfg.Name.Mode == "DisplayName" and plr.DisplayName or plr.Name, "lowercase")
        c.NameLbl.TextColor3 = self.cfg.Name.Color
        c.NameLbl.FontFace = Fonts[self.cfg.Font]
        c.NameLbl.TextSize = self.cfg.TextSize
        c.NameLbl.Position = UDim2.fromOffset(tx - c.NameLbl.TextBounds.X / 2, ty - 18)
    else
        c.NameLbl.Visible = false
    end

    if self.cfg.Weapon.Enabled then
        c.WeapLbl.Visible = true
        local tool = char:FindFirstChildOfClass("Tool")
        c.WeapLbl.Text = GetCase(tool and tool.Name or "None", "lowercase")
        c.WeapLbl.TextColor3 = self.cfg.Weapon.Color
        c.WeapLbl.FontFace = Fonts[self.cfg.Font]
        c.WeapLbl.TextSize = self.cfg.TextSize
        c.WeapLbl.Position = UDim2.fromOffset(tx - c.WeapLbl.TextBounds.X / 2, ty + scale.Y + 2)
    else
        c.WeapLbl.Visible = false
    end

    if self.cfg.Distance.Enabled then
        c.DistLbl.Visible = true
        c.DistLbl.Text = GetCase(string.format("[%.0f]", dist * 0.28), "lowercase")
        c.DistLbl.TextColor3 = self.cfg.Distance.Color
        c.DistLbl.FontFace = Fonts[self.cfg.Font]
        c.DistLbl.TextSize = self.cfg.TextSize
        c.DistLbl.Position = UDim2.fromOffset(tx - c.DistLbl.TextBounds.X / 2, ty + scale.Y + 16)
    else
        c.DistLbl.Visible = false
    end
end

function ESP:BuildUI(tab)
    local L = tab:AddLeftGroupbox("Player ESP", "eye")
    local R = tab:AddRightGroupbox("Text & Bars", "type")

    local b = L:AddToggle("ESP_Box", { Text = "Box", Default = false, Callback = function(v) self.cfg.Box.Enabled = v end })
    b:AddColorPicker("BoxColor", { Default = self.cfg.Box.Color, Callback = function(v) self.cfg.Box.Color = v end })

    local f = L:AddToggle("ESP_Filled", { Text = "Filled Box", Default = false, Callback = function(v) self.cfg.Box.Filled = v end })
    f:AddColorPicker("FillColor", { Default = self.cfg.Box.FillColor, Callback = function(v) self.cfg.Box.FillColor = v end })
    f:AddSlider("FillTrans", { Text = "Fill Transparency", Default = 0.5, Min = 0, Max = 1, Rounding = 2, Callback = function(v) self.cfg.Box.FillTransparency = v end })

    local hl = L:AddToggle("ESP_Highlight", { Text = "Highlight", Default = false, Callback = function(v)
        self.cfg.Highlight.Enabled = v
        if not v then for p in pairs(self.cache) do self:RemoveHighlight(p) end end
    end })
    hl:AddColorPicker("HLFill", { Default = self.cfg.Highlight.Color, Callback = function(v) self.cfg.Highlight.Color = v end })
    hl:AddColorPicker("HLOutline", { Default = self.cfg.Highlight.Outline, Callback = function(v) self.cfg.Highlight.Outline = v end })
    L:AddToggle("HL_Walls", { Text = "Behind Walls", Default = false, Callback = function(v) self.cfg.Highlight.BehindWalls = v end })

    local ch = L:AddToggle("ESP_Chams", { Text = "Chams", Default = false, Callback = function(v)
        self.cfg.Chams.Enabled = v
        if not v then for p in pairs(self.cache) do self:RemoveChams(p) end end
    end })
    ch:AddColorPicker("ChamsColor", { Default = self.cfg.Chams.Color, Callback = function(v) self.cfg.Chams.Color = v end })
    L:AddToggle("Chams_Walls", { Text = "Chams Behind Walls", Default = false, Callback = function(v) self.cfg.Chams.BehindWalls = v end })

    L:AddDivider()
    local mat = L:AddToggle("ESP_Material", { Text = "Material Override", Default = false, Callback = function(v)
        self.cfg.Material.Enabled = v
        if not v then for p, c in pairs(self.cache) do if c.MatApplied then self:RemoveMaterial(p, c.Character) c.MatApplied = false end end end
    end })
    mat:AddColorPicker("MatColor", { Default = self.cfg.Material.Color, Callback = function(v) self.cfg.Material.Color = v end })
    L:AddDropdown("MatType", { Values = {"ForceField", "Neon", "Glass", "SmoothPlastic"}, Default = "ForceField", Text = "Material", Callback = function(v) self.cfg.Material.Type = Enum.Material[v] end })

    R:AddDivider()

    local nt = R:AddToggle("ESP_Name", { Text = "Name", Default = false, Callback = function(v) self.cfg.Name.Enabled = v end })
    nt:AddColorPicker("NameColor", { Default = self.cfg.Name.Color, Callback = function(v) self.cfg.Name.Color = v end })
    R:AddDropdown("NameMode", { Values = {"DisplayName", "Username"}, Default = "DisplayName", Text = "Type", Callback = function(v) self.cfg.Name.Mode = v end })

    local wt = R:AddToggle("ESP_Weapon", { Text = "Weapon", Default = false, Callback = function(v) self.cfg.Weapon.Enabled = v end })
    wt:AddColorPicker("WepColor", { Default = self.cfg.Weapon.Color, Callback = function(v) self.cfg.Weapon.Color = v end })

    local dt = R:AddToggle("ESP_Dist", { Text = "Distance", Default = false, Callback = function(v) self.cfg.Distance.Enabled = v end })
    dt:AddColorPicker("DistColor", { Default = self.cfg.Distance.Color, Callback = function(v) self.cfg.Distance.Color = v end })

    R:AddDropdown("ESPFont", { Values = {"SourceSans", "SourceSans Bold", "Gotham", "Gotham Bold", "Minecraft", "Cartoon"}, Default = "SourceSans Bold", Text = "Font", Callback = function(v) self.cfg.Font = v end })
    R:AddSlider("TextSize", { Text = "Text Size", Default = 12, Min = 8, Max = 20, Rounding = 0, Callback = function(v) self.cfg.TextSize = v end })

    R:AddDivider()

    local hb = R:AddToggle("ESP_HpBar", { Text = "Health Bar", Default = false, Callback = function(v) self.cfg.HealthBar.Enabled = v end })
    hb:AddColorPicker("HpColor", { Default = self.cfg.HealthBar.Color, Callback = function(v) self.cfg.HealthBar.Color = v end })

    local ab = R:AddToggle("ESP_ArmorBar", { Text = "Armor Bar", Default = false, Callback = function(v) self.cfg.ArmorBar.Enabled = v end })
    ab:AddColorPicker("ArmorColor", { Default = self.cfg.ArmorBar.Color, Callback = function(v) self.cfg.ArmorBar.Color = v end })

    R:AddDivider()

    local mt = R:AddToggle("ESP_Enabled", { Text = "Enable ESP", Default = false, Callback = function(v)
        self.cfg.Enabled = v
        if v then
            for _, p in ipairs(Players:GetPlayers()) do if p ~= Players.LocalPlayer then self:SetupPlayer(p) end end
        else
            self:CleanupAll()
        end
    end })
    mt:AddKeyPicker("ESP_Keybind", { Text = "Toggle", Default = "None", Mode = "Toggle", SyncToggleState = true, Callback = function(v)
        self.cfg.Enabled = v
        if v then for _, p in ipairs(Players:GetPlayers()) do if p ~= Players.LocalPlayer then self:SetupPlayer(p) end end else self:CleanupAll() end
    end })
end

function ESP:Hook()
    self:Unhook()
    self.conns.PlayerAdded = Players.PlayerAdded:Connect(function(p)
        if p ~= Players.LocalPlayer and self.cfg.Enabled then self:SetupPlayer(p) end
    end)
    self.conns.PlayerRemoving = Players.PlayerRemoving:Connect(function(p)
        if p ~= Players.LocalPlayer then self:CleanupPlayer(p) end
    end)
    self.conns.Render = RunService.RenderStepped:Connect(function()
        if not self.cfg.Enabled then return end
        for p in pairs(self.cache) do if p then self:UpdatePlayer(p) end end
    end)
end

function ESP:Unhook()
    for _, c in pairs(self.conns) do c:Disconnect() end
    self.conns = {}
end

function ESP:Cleanup()
    self.cfg.Enabled = false
    self:Unhook()
    self:CleanupAll()
end

return ESP