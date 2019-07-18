local addon, _g = ...

_g.Class = {}
_g.Class.__index = Class

function _g.Class:new(data)
	local instance = data or {}
	setmetatable(instance, self)
	instance.__index = instance
	return instance
end
