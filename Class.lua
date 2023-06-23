local Object = require("Object")
local ClassMT = {}
local Class = setmetatable({}, ClassMT)
local InstanceMT = {
	__call = function(self, ...)
		return Object(self, ...)
	end,
}
function ClassMT:__call(instance)
	if instance == nil then
		instance = {}
	end
	return setmetatable(instance, InstanceMT)
end
return Class
-- Compiled with Erde 0.6.0-1
-- __ERDE_COMPILED__
