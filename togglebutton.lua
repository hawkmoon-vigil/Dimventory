local addon, _g = ...

_g.btnToggle = _g.Context.CreateTextureButton(	
	"btnAddRemove",
	"img/btn_zoomin_(normal).png",
	"img/btn_zoomin_(over).png")
	
function _g.btnToggle:LeftClick()
	if _g.data.currentDimension then
		_g.print(_g.data.currentDimension .. " removed.")
		_g.data.removeDimension()
	else
		_g.textInputDialog:ShowDialog()
	end
end

function _g.btnToggle:UpdateTextures()
	if _g.data.currentDimension then
		self:ChangeTextures("img/btn_zoomout_(normal).png", "img/btn_zoomout_(over).png")
		self:SetVisible(true)
 	elseif not Inspect.Dimension.Layout.List() then
		self:SetVisible(false)
	else
		self:ChangeTextures("img/btn_zoomin_(normal).png", "img/btn_zoomin_(over).png")
		self:SetVisible(true)
	end
end

function _g.btnToggle:SetInitialPosition()
	self._texture:ClearAll()
	if DIUISave and DIUISave.buttons then
		local data = DIUISave.buttons[self._name]
		if data then
			self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", data.x, data.y)
			return
		end
	end

	self:SetPoint("TOPRIGHT", UI.Native.MapMini, "TOPRIGHT", 0, 24)
end