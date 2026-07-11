local ESP = {}
ESP.__index = ESP

function ESP:Initialize(Tab)
	local self = setmetatable({}, ESP)
	
	if not getgenv().DeepESP then
		getgenv().DeepESP = {Functions = {}, Settings = {}}
	end
	
	self.ESPEnv = getgenv().DeepESP
	self.Players = game:GetService("Players")
	self.LocalPlayer = self.Players.LocalPlayer
	self.ESP_DB = false
	
	self:ResetSettings()
	self:CreateUI(Tab)
	self:Start()
	
	return self
end

function ESP:ResetSettings()
	self.Settings = {
		Enabled = false,
		TeamCheck = false,
		PlayerName = "Name",
		FillTransparency = 0.5,
		OutlineTransparency = 0,
		TextSize = 18,
		TextFont = "SciFi",
		ShowDistance = true,
		UseTeamColor = true,
	}
end

function ESP:CreateUI(Tab)
	local Main = Tab:AddLeftGroupbox("ESP Settings")
	local Visuals = Tab:AddRightGroupbox("ESP Visuals")
	
	Main:AddToggle("DeepESPEnabled", {
		Text = "Enabled",
		Default = false,
		Callback = function(v) 
			self.Settings.Enabled = v
			if v then self:Restart() else self:Stop() end
		end
	})
	
	Main:AddToggle("ESPTeamCheck", {
		Text = "Team Check",
		Default = false,
		Callback = function(v) 
			self.Settings.TeamCheck = v
			self:Restart()
		end
	})
	
	Main:AddDropdown("ESPPlayerName", {
		Values = {"Name", "DisplayName"},
		Default = "Name",
		Text = "Player Name Type",
		Callback = function(v) self.Settings.PlayerName = v end
	})
	
	Main:AddToggle("ESPShowDistance", {
		Text = "Show Distance",
		Default = true,
		Callback = function(v) self.Settings.ShowDistance = v end
	})
	
	Main:AddToggle("ESPUseTeamColor", {
		Text = "Use Team Color",
		Default = true,
		Callback = function(v) 
			self.Settings.UseTeamColor = v
			self:Restart()
		end
	})
	
	Visuals:AddSlider("ESPFillTransparency", {
		Text = "Fill Transparency",
		Default = 0.5,
		Min = 0, Max = 1, Rounding = 2,
		Callback = function(v) self.Settings.FillTransparency = v end
	})
	
	Visuals:AddSlider("ESPOutlineTransparency", {
		Text = "Outline Transparency",
		Default = 0,
		Min = 0, Max = 1, Rounding = 2,
		Callback = function(v) self.Settings.OutlineTransparency = v end
	})
	
	Visuals:AddSlider("ESPTextSize", {
		Text = "Text Size",
		Default = 18,
		Min = 10, Max = 30,
		Callback = function(v) self.Settings.TextSize = v end
	})
	
	Visuals:AddDropdown("ESPTextFont", {
		Values = {"SciFi", "Arial", "Fantasy", "Gotham", "Legacy", "SourceSans"},
		Default = "SciFi",
		Text = "Text Font",
		Callback = function(v) self.Settings.TextFont = v end
	})
end

-- Остальные методы ESP
function ESP:UpdateESP() ... end
function ESP:RemoveESP() ... end

function ESP:Cleanup()
	self:Stop()
end

return ESP
