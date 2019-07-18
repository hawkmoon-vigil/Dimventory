local addon, _g = ...

_g.TextureButton = _g.Class:new()

function _g.TextureButton:new(name, normalTexture, overTexture, context)
	local button = _g.Class:new()
	setmetatable(button, self)
	button.__index = ability
	button._texture = UI.CreateFrame("Texture", name, context)
	button._texture:SetTexture("Dimventory", normalTexture)
	button._normalImg = normalTexture
	button._overImg = overTexture
	function button._texture.Event:MouseIn()
		button._mouseIn = true
		button._texture:SetTexture("Dimventory", button._normalImg)
	end
	function button._texture.Event:MouseOut()
		button._mouseIn = false
		button._texture:SetTexture("Dimventory", button._overImg)
	end
	
	function button._texture.Event:LeftClick()
		button:LeftClick()
	end
	
	return button
end

function _g.TextureButton:LeftClick()
	error("should override this")
end

function _g.TextureButton:SetPoint(pointOnThis, targetFrame, pointOnOther, xoffset, yoffset)
	self._texture:SetPoint(pointOnThis, targetFrame, pointOnOther, xoffset or 0, yoffset or 0)
end

function _g.TextureButton:ChangeTextures(normalTexture, overTexture)
	self._normalImg = normalTexture
	self._overImg = overTexture
	if self._mouseIn then
		self._texture:SetTexture("Dimventory", self._overImg)
	else
		self._texture:SetTexture("Dimventory", self._normalImg)
	end
end

function _g.TextureButton:SetVisible(flag)
	self._texture:SetVisible(flag)
end