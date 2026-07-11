local ModuleLoader = {}
ModuleLoader.__index = ModuleLoader

function ModuleLoader:LoadModule(moduleName, ...)
	local module = loadstring(game:HttpGet(self.Repo .. "modules/" .. moduleName .. ".lua"))()
	return module:Initialize(...)
end

return setmetatable({Repo = game:HttpGet("")}, ModuleLoader)
