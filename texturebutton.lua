local addon, _g = ...

_g.TextureButton = _g.Class:new()

function _g.TextureButton:new(name, normalTexture, overTexture, context)
	local button = _g.Class:new()
	setmetatable(button, self)
	button.__index = ability
	button._texture = UI.CreateFrame("Texture", name, context)
	button._name = name
	button._texture:SetTexture("Dimventory", normalTexture)
	button._normalImg = normalTexture
	button._overImg = overTexture
	button._draggable = true
	button._texture.parent = button
	
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
	
	function button._texture.Event:RightDown()
		if not self.parent._draggable then
			return
		end

		local mouseData = Inspect.Mouse()
		self._xOffset = self:GetLeft() - mouseData.x
		self._yOffset = self:GetTop() - mouseData.y
		self:ClearAll()
		self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", self._xOffset, self._yOffset)
		local mouseData = Inspect.Mouse()
		self.rightDown = true
	end
	
	function button._texture.Event:RightUp()
		if not self.parent._draggable then
			return
		end
		
		_g.data.saveButtonPosition(self.parent._name, self:GetLeft(), self:GetTop())
		self.rightDown = false
	end

	function button._texture.Event:MouseMove(mouseX, mouseY)
		if not self.parent._draggable or not self.rightDown then
			return
		end

		self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", mouseX + self._xOffset, mouseY + self._yOffset)
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

function _g.TextureButton:SetInitialPosition()
end