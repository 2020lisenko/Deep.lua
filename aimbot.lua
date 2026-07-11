local Aimbot = {}
Aimbot.__index = Aimbot

function Aimbot:Initialize(Tab)
	local self = setmetatable({}, Aimbot)
	
	-- Инициализация Deep (если еще не инициализирован)
	if not getgenv().Deep then
		getgenv().Deep = {Functions = {}, Settings = {}, FOVSettings = {}}
	end
	
	self.DeepEnv = getgenv().Deep
	self.ServiceConnections = {}
	self.Running = false
	self.Typing = false
	
	-- Сервисы
	self.RunService = game:GetService("RunService")
	self.UserInputService = game:GetService("UserInputService")
	self.TweenService = game:GetService("TweenService")
	self.Players = game:GetService("Players")
	self.Camera = workspace.CurrentCamera
	self.LocalPlayer = self.Players.LocalPlayer
	
	-- Настройки по умолчанию
	self:ResetSettings()
	
	-- Создание UI
	self:CreateUI(Tab)
	
	-- Инициализация FOV Circle
	self.FOVCircle = Drawing.new("Circle")
	
	-- Запуск
	self:Start()
	
	return self
end

function Aimbot:ResetSettings()
	self.Settings = {
		Enabled = false,
		TeamCheck = false,
		AliveCheck = true,
		WallCheck = false,
		Sensitivity = 0,
		ThirdPerson = false,
		ThirdPersonSensitivity = 3,
		TriggerKey = "MouseButton2",
		Toggle = false,
		LockPart = "Head"
	}
	
	self.FOVSettings = {
		Enabled = false,
		Visible = true,
		Amount = 90,
		Color = Color3.fromRGB(255, 255, 255),
		LockedColor = Color3.fromRGB(255, 70, 70),
		Transparency = 0.5,
		Sides = 60,
		Thickness = 1,
		Filled = false
	}
end

function Aimbot:CreateUI(Tab)
	local Main = Tab:AddLeftGroupbox("Main Settings")
	local Right = Tab:AddRightGroupbox("Aim Settings")
	local FOV = Tab:AddRightGroupbox("FOV Settings")
	
	-- Main Settings
	Main:AddToggle("DeepAimbotEnabled", {
		Text = "Enabled",
		Default = false,
		Callback = function(v) self.Settings.Enabled = v end
	})
	
	Main:AddDropdown("LockPart", {
		Values = {"Head", "HumanoidRootPart", "Torso", "UpperTorso"},
		Default = "Head",
		Text = "Lock Part",
		Callback = function(v) self.Settings.LockPart = v end
	})
	
	Main:AddDropdown("TriggerKey", {
		Values = {"MouseButton1", "MouseButton2", "E", "Q", "F", "T", "Shift", "Control"},
		Default = "MouseButton2",
		Text = "Trigger Key",
		Callback = function(v) self:UpdateTriggerKey(v) end
	})
	
	Main:AddToggle("ToggleMode", {
		Text = "Toggle Mode",
		Default = false,
		Callback = function(v) 
			self.Settings.Toggle = v
			self:Restart()
		end
	})
	
	Main:AddToggle("TeamCheck", {
		Text = "Team Check",
		Default = false,
		Callback = function(v) self.Settings.TeamCheck = v end
	})
	
	Main:AddToggle("AliveCheck", {
		Text = "Alive Check",
		Default = true,
		Callback = function(v) self.Settings.AliveCheck = v end
	})
	
	Main:AddToggle("WallCheck", {
		Text = "Wall Check",
		Default = false,
		Callback = function(v) self.Settings.WallCheck = v end
	})
	
	-- Aim Settings
	Right:AddSlider("Sensitivity", {
		Text = "Smoothness",
		Default = 0,
		Min = 0,
		Max = 1,
		Rounding = 2,
		Callback = function(v) self.Settings.Sensitivity = v end
	})
	
	Right:AddToggle("ThirdPerson", {
		Text = "Third Person Mode",
		Default = false,
		Callback = function(v) 
			self.Settings.ThirdPerson = v
			self:Restart()
		end
	})
	
	Right:AddSlider("ThirdPersonSensitivity", {
		Text = "Third Person Sensitivity",
		Default = 3,
		Min = 0.1,
		Max = 5,
		Rounding = 1,
		Callback = function(v) self.Settings.ThirdPersonSensitivity = v end
	})
	
	-- FOV Settings
	FOV:AddToggle("FOVEnabled", {
		Text = "Show FOV Circle",
		Default = false,
		Callback = function(v) self.FOVSettings.Enabled = v end
	})
	
	FOV:AddSlider("FOVAmount", {
		Text = "FOV Size",
		Default = 90,
		Min = 10,
		Max = 500,
		Callback = function(v) self.FOVSettings.Amount = v end
	})
	
	FOV:AddSlider("FOVTransparency", {
		Text = "Transparency",
		Default = 0.5,
		Min = 0,
		Max = 1,
		Rounding = 2,
		Callback = function(v) self.FOVSettings.Transparency = v end
	})
	
	FOV:AddSlider("FOVThickness", {
		Text = "Thickness",
		Default = 1,
		Min = 1,
		Max = 10,
		Callback = function(v) self.FOVSettings.Thickness = v end
	})
	
	FOV:AddToggle("FOVFilled", {
		Text = "Filled Circle",
		Default = false,
		Callback = function(v) self.FOVSettings.Filled = v end
	})
	
	FOV:AddLabel("FOV Color"):AddColorPicker("FOVColor", {
		Default = Color3.fromRGB(255, 255, 255),
		Callback = function(v) self.FOVSettings.Color = v end
	})
	
	FOV:AddLabel("Locked FOV Color"):AddColorPicker("FOVLockedColor", {
		Default = Color3.fromRGB(255, 70, 70),
		Callback = function(v) self.FOVSettings.LockedColor = v end
	})
end

function Aimbot:Start()
	self:SetupConnections()
end

function Aimbot:SetupConnections()
	self:DisconnectAll()
	
	self.ServiceConnections.TypingStarted = self.UserInputService.TextBoxFocused:Connect(function()
		self.Typing = true
	end)
	
	self.ServiceConnections.TypingEnded = self.UserInputService.TextBoxFocusReleased:Connect(function()
		self.Typing = false
	end)
	
	self.ServiceConnections.RenderStepped = self.RunService.RenderStepped:Connect(function()
		self:UpdateFOV()
		self:UpdateAimbot()
	end)
	
	self.ServiceConnections.InputBegan = self.UserInputService.InputBegan:Connect(function(input)
		self:HandleInput(input, true)
	end)
	
	self.ServiceConnections.InputEnded = self.UserInputService.InputEnded:Connect(function(input)
		self:HandleInput(input, false)
	end)
end

function Aimbot:HandleInput(input, began)
	if self.Typing then return end
	
	local keyMatch = false
	pcall(function()
		keyMatch = input.KeyCode == Enum.KeyCode[self.Settings.TriggerKey]
	end)
	
	if not keyMatch then
		pcall(function()
			keyMatch = input.UserInputType == Enum.UserInputType[self.Settings.TriggerKey]
		end)
	end
	
	if keyMatch then
		if self.Settings.Toggle then
			if began then
				self.Running = not self.Running
				if not self.Running then self:CancelLock() end
			end
		else
			self.Running = began
			if not began then self:CancelLock() end
		end
	end
end

-- Остальные методы из оригинального скрипта
function Aimbot:UpdateFOV() ... end
function Aimbot:UpdateAimbot() ... end
function Aimbot:GetClosestPlayer() ... end
function Aimbot:CancelLock() ... end

function Aimbot:Cleanup()
	self:DisconnectAll()
	if self.FOVCircle.Remove then
		self.FOVCircle:Remove()
	end
end

return Aimbot
