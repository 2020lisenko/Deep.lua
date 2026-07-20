local ESP = {}

function ESP:Initialize(Tab)
    print("ESP module initializing...")
    
    -- Настройки
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
    
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local CoreGui = game:GetService("CoreGui")
    local GuiInset = game:GetService("GuiService"):GetGuiInset()
    
    local Cache = {}
    local RotationAngle, LastTick = -45, tick()
    local Increase = Vector3.new(2, 2, 2)
    local Vertices = { 
        { -0.5, -0.5, -0.5 }, { -0.5, 0.5, -0.5 }, { 0.5, -0.5, -0.5 }, { 0.5, 0.5, -0.5 }, 
        { -0.5, -0.5, 0.5 }, { -0.5, 0.5, 0.5 }, { 0.5, -0.5, 0.5 }, { 0.5, 0.5, 0.5 } 
    }
    
    -- Utility Functions
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
        
        if Cache[Player] then
            Cache[Player].Highlight = H
        end
    end
    
    local function CreateChams(Player, Character)
        if Cache[Player] and Cache[Player].Chams then
            for _, c in ipairs(Cache[Player].Chams) do
                c:Destroy()
            end
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
            Box.Size = Part.Size + Vector3.new(0.01, 0.01, 0.01)
            Box.Parent = CoreGui
            ChamsList[#ChamsList + 1] = Box
        end
        
        if Cache[Player] then
            Cache[Player].Chams = ChamsList
        end
    end
    
    local function Render(Player)
        if not Player then return end
        
        Cache[Player] = Cache[Player] or {}
        Cache[Player].Box = {}
        Cache[Player].Bars = {}
        Cache[Player].Text = {}
        Cache[Player].Highlight = nil
        Cache[Player].Chams = nil
        Cache[Player].Character = Player.Character
        
        local BoxGui = Instance.new("ScreenGui")
        BoxGui.Name = Player.Name .. "_BoxESP"
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
        Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        Stroke.Parent = BoxFrame
        
        local Gradient = Instance.new("UIGradient")
        Gradient.Rotation = 45
        Gradient.Parent = Stroke
        
        local FillFrame = Instance.new("Frame")
        FillFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        FillFrame.BackgroundTransparency = 0.5
        FillFrame.Size = UDim2.new(1, 0, 1, 0)
        FillFrame.Visible = false
        FillFrame.Parent = BoxContainer
        
        local FillGradient = Instance.new("UIGradient")
        FillGradient.Rotation = 45
        FillGradient.Parent = FillFrame
        
        Cache[Player].Box = {
            Box = BoxContainer,
            Stroke = Stroke,
            Gradient = Gradient,
            Fill = FillFrame,
            FillGradient = FillGradient
        }
        
        local NameGui = Instance.new("ScreenGui")
        NameGui.Parent = CoreGui
        local NameLabel = Instance.new("TextLabel")
        NameLabel.BackgroundTransparency = 1
        NameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        NameLabel.TextStrokeTransparency = 0
        NameLabel.TextSize = 10
        NameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        NameLabel.Parent = NameGui
        Cache[Player].Text.Name = NameLabel
        
        local DistanceGui = Instance.new("ScreenGui")
        DistanceGui.Parent = CoreGui
        local DistanceLabel = Instance.new("TextLabel")
        DistanceLabel.BackgroundTransparency = 1
        DistanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        DistanceLabel.TextStrokeTransparency = 0
        DistanceLabel.TextSize = 10
        DistanceLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
        DistanceLabel.Parent = DistanceGui
        Cache[Player].Text.Distance = DistanceLabel
        
        if Player.Character then
            if Config.Highlight.Enabled then
                CreateHighlight(Player, Player.Character)
            end
            if Config.Chams.Enabled then
                CreateChams(Player, Player.Character)
            end
        end
    end
    
    local function ClearESP(Player)
        if not Cache[Player] then return end
        
        if Cache[Player].Box and Cache[Player].Box.Box then
            Cache[Player].Box.Box:Destroy()
        end
        if Cache[Player].Text then
            if Cache[Player].Text.Name then Cache[Player].Text.Name.Parent:Destroy() end
            if Cache[Player].Text.Distance then Cache[Player].Text.Distance.Parent:Destroy() end
        end
        if Cache[Player].Highlight then
            Cache[Player].Highlight:Destroy()
        end
        if Cache[Player].Chams then
            for _, c in ipairs(Cache[Player].Chams) do
                c:Destroy()
            end
        end
        
        Cache[Player] = nil
    end
    
    local function Update(Player)
        if not Player or not Cache[Player] then return end
        
        local Character = Player.Character
        local ClientCharacter = LocalPlayer.Character
        
        if not Character or not ClientCharacter then
            ClearESP(Player)
            return
        end
        
        local RootPart = Character:FindFirstChild("HumanoidRootPart")
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if not RootPart or not Humanoid then
            ClearESP(Player)
            return
        end
        
        local CF, Size3D, Center = CustomBounds(Character)
        if not CF then
            ClearESP(Player)
            return
        end
        
        local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Center)
        if not OnScreen then
            ClearESP(Player)
            return
        end
        
        local Distance = (Camera.CFrame.Position - Center).Magnitude
        local Height = math.tan(math.rad(Camera.FieldOfView / 2)) * 2 * Distance
        local Scale = Vector2.new((Camera.ViewportSize.Y / Height) * Size3D.X, (Camera.ViewportSize.Y / Height) * Size3D.Y)
        local Position = Vector2.new(ScreenPos.X - Scale.X / 2, ScreenPos.Y - Scale.Y / 2)
        
        local PlayerCache = Cache[Player]
        
        if Config.Box.Enabled and PlayerCache.Box.Box then
            PlayerCache.Box.Box.Visible = true
            PlayerCache.Box.Box.Position = UDim2.new(0, Position.X, 0, Position.Y - GuiInset.Y)
            PlayerCache.Box.Box.Size = UDim2.new(0, Scale.X, 0, Scale.Y)
            
            if PlayerCache.Box.Gradient then
                PlayerCache.Box.Gradient.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, Config.Box.Gradient.Color1),
                    ColorSequenceKeypoint.new(0.5, Config.Box.Gradient.Color2),
                    ColorSequenceKeypoint.new(1, Config.Box.Gradient.Color3)
                })
            end
            
            if Config.Box.Filled.Enabled and PlayerCache.Box.Fill then
                PlayerCache.Box.Fill.Visible = true
                if PlayerCache.Box.FillGradient then
                    PlayerCache.Box.FillGradient.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Config.Box.Filled.Gradient.Color1),
                        ColorSequenceKeypoint.new(0.5, Config.Box.Filled.Gradient.Color2),
                        ColorSequenceKeypoint.new(1, Config.Box.Filled.Gradient.Color3)
                    })
                end
            end
        elseif PlayerCache.Box.Box then
            PlayerCache.Box.Box.Visible = false
        end
        
        if Config.Text.Name.Enabled and PlayerCache.Text.Name then
            local label = PlayerCache.Text.Name
            label.Visible = true
            label.Position = UDim2.new(0, Position.X + Scale.X/2 - label.AbsoluteSize.X/2, 0, Position.Y - GuiInset.Y - 15)
            label.TextColor3 = Config.Text.Name.Color
            label.Text = Config.Text.Name.Type == "DisplayName" and Player.DisplayName or Player.Name
        elseif PlayerCache.Text.Name then
            PlayerCache.Text.Name.Visible = false
        end
        
        if Config.Text.Distance.Enabled and PlayerCache.Text.Distance then
            local label = PlayerCache.Text.Distance
            label.Visible = true
            label.Position = UDim2.new(0, Position.X + Scale.X/2 - label.AbsoluteSize.X/2, 0, Position.Y - GuiInset.Y + Scale.Y + 5)
            label.TextColor3 = Config.Text.Distance.Color
            label.Text = string.format("[%.0f]", Distance * 0.28)
        elseif PlayerCache.Text.Distance then
            PlayerCache.Text.Distance.Visible = false
        end
    end
    
    -- Connections
    local Heartbeat
    local function StartESP()
        for _, Player in ipairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer then
                Render(Player)
            end
        end
        
        Players.PlayerAdded:Connect(function(Player)
            if Player ~= LocalPlayer then
                Render(Player)
            end
        end)
        
        Players.PlayerRemoving:Connect(function(Player)
            ClearESP(Player)
        end)
        
        Heartbeat = RunService.Heartbeat:Connect(function()
            for Player, _ in pairs(Cache) do
                if Player then
                    Update(Player)
                end
            end
        end)
    end
    
    local function StopESP()
        if Heartbeat then
            Heartbeat:Disconnect()
            Heartbeat = nil
        end
        for Player, _ in pairs(Cache) do
            ClearESP(Player)
        end
    end
    
    -- UI
    local BoxGroup = Tab:AddLeftGroupbox("Box ESP")
    local TextGroup = Tab:AddRightGroupbox("Text ESP")
    local ExtraGroup = Tab:AddLeftGroupbox("Extra")
    
    BoxGroup:AddToggle("BoxEnabled", {
        Text = "Box ESP",
        Default = false,
        Callback = function(v)
            Config.Box.Enabled = v
        end
    })
    
    BoxGroup:AddToggle("BoxFilled", {
        Text = "Filled Box",
        Default = false,
        Callback = function(v)
            Config.Box.Filled.Enabled = v
        end
    })
    
    TextGroup:AddToggle("NameEnabled", {
        Text = "Name",
        Default = false,
        Callback = function(v)
            Config.Text.Name.Enabled = v
        end
    })
    
    TextGroup:AddToggle("DistanceEnabled", {
        Text = "Distance",
        Default = false,
        Callback = function(v)
            Config.Text.Distance.Enabled = v
        end
    })
    
    ExtraGroup:AddToggle("HighlightEnabled", {
        Text = "Highlight",
        Default = false,
        Callback = function(v)
            Config.Highlight.Enabled = v
        end
    })
    
    ExtraGroup:AddToggle("ChamsEnabled", {
        Text = "Chams",
        Default = false,
        Callback = function(v)
            Config.Chams.Enabled = v
        end
    })
    
    -- Start ESP
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
