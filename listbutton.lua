local addon, _g = ...

_g.btnList = _g.Context.CreateTextureButton(
	"btnList",
	"img/btn_dimensions_top_manage_(normal).png",
	"img/btn_dimensions_top_manage_(over).png")

function _g.btnList:LeftClick()
	if DimensionInventorySave and next(DimensionInventorySave) then
		_g.dataGrid:SetVisible(true)
	end
end

function _g.btnList:SetInitialPosition()
	self._texture:ClearAll()
	if DIUISave and DIUISave.buttons then
		local data = DIUISave.buttons[self._name]
		if data then
			self:SetPoint("TOPLEFT", UIParent, "TOPLEFT", data.x, data.y)
			return
		end
	end

	self:SetPoint("BOTTOMRIGHT", UI.Native.MapMini, "BOTTOMRIGHT", -10, -10)
end