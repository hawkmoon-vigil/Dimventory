local addon, _g = ...

_g.btnToggle = _g.Context.CreateTextureButton(	
	"btnAddRemove",
	"img/btn_zoomin_(normal).png",
	"img/btn_zoomin_(over).png")
_g.btnToggle:SetPoint("TOPRIGHT", UI.Native.MapMini, "TOPRIGHT", 0, 24)

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