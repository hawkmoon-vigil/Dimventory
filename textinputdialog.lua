local addon, _g = ...

_g.TextInputDialog = _g.Class:new()

function _g.TextInputDialog:SetWidth(x)
	self._frame:SetWidth(x)
end

function _g.TextInputDialog:SetHeight(y)
	self._frame:SetHeight(y)
end

function _g.TextInputDialog:SetPoint(loc1, parent, loc2, offsetx, offsety)
	self._frame:SetPoint(loc1, parent, loc2, offsetx or 0, offsety or 0)
end

function _g.TextInputDialog:SetVisible(flag)
	self._frame:SetVisible(flag)
end

function _g.TextInputDialog:Init(name, text, width, height, context)
	self.__index = self
	self._text = text
	self._frame = UI.CreateFrame("SimpleWindow", name, context)
	self._frame:SetCloseButtonVisible(false)
	self._frame:SetLayer(10000)
	self:SetWidth(width)
	self:SetHeight(height)
	self:SetPoint("CENTER", UIParent, "CENTER")
	
	self._lbl = _g.Context.CreateLabel("lblName", text, self._frame);
	self._lbl:SetPoint("TOPLEFT", self._frame, "TOPLEFT", 40, 40)
	self._lbl:SetFontSize(14)
	
	self._txt = _g.Context.CreateTextBox("txtName", "", self._frame);
	self._txt:SetPoint("TOPLEFT", self._frame, "TOPLEFT", 40, 70)
	self._txt:SetWidth(250)
	self._txt:SetBackgroundColor(0, 0, 0, 1)
	self._txt._parent = self
	
	function self._txt.Event:TextfieldChange()
		local text = (self:GetText():gsub("^%s*(.-)%s*$", "%1"))
		if not text or text == "" then
			self._parent._btnOK:SetEnabled(false)
			return
		end
		
		for shard, shardData in pairs(DimensionInventorySave) do
			for dimType, dimArray in pairs(shardData) do
				for _, dim in ipairs(dimArray) do
					if text == dim.name then
						self._parent._btnOK:SetEnabled(false)
						return
					end
				end
			end
		end
		
		self._parent._btnOK:SetEnabled(true)
	end
	
	self._btnCancel = _g.Context.CreateButton("btnCancel", "Cancel", self._frame)
	self._btnCancel:SetPoint("BOTTOMRIGHT", self._frame, "BOTTOMRIGHT", -20, -20)
	self._btnCancel._parent = self
	
	self._btnOK = _g.Context.CreateButton("btnOK", "OK", self._frame)
	self._btnOK:SetPoint("BOTTOMRIGHT", self._frame, "BOTTOMRIGHT", -160, -20)
	self._btnOK._parent = self
	self._btnOK:SetEnabled(false)

	function self._btnOK.Event:LeftPress()
		self._parent.value = self._parent._txt:GetText()
		self._parent:OKPress()
		self._parent:SetVisible(false)
	end

	function self._btnCancel.Event:LeftPress()
		self._parent:SetVisible(false)
		self._parent._txt:SetKeyFocus(false)
	end
end


function _g.TextInputDialog:new(name, text, width, height, context)
	local dialog = _g.Class:new()
	setmetatable(dialog, self)
	dialog:Init(name, text, width, height, context)
	return dialog
end

_g.textInputDialog = _g.Context.CreateTextInputDialog("", "Friendly Name", 400, 160)
_g.textInputDialog:SetVisible(false)

function _g.textInputDialog:OKPress()
	self:SetVisible(false)
	_g.print("Adding dimension: " .. self.value)
	_g.data.addDimension(self.value)
end

function _g.textInputDialog:ShowDialog()
	local detail = Inspect.Unit.Detail("player")
	local dimName = detail.locationName
	if string.find(dimName, "Dimension: ") then
		dimName = string.sub(dimName, 12, -1)
	end
	
	self._txt:SetText(dimName .. " - " .. detail.name)
	self._txt.Event.TextfieldChange(self._txt)
	self:SetVisible(true)
end

