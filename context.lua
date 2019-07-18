local addon, _g = ...

local _context = UI.CreateContext("Dimventory_context")

_g.Context = {}

function _g.Context.CreateDialog(name, text, parent)
	return _g.Dialog:new(name, text, parent or _context)
end

function _g.Context.CreateLabel(name, text, parent)
	local txt = UI.CreateFrame("Text", name, parent or _context)
	txt:SetText(text)
	return txt
end

function _g.Context.CreateTextBox(name, text, parent)
	local txt = UI.CreateFrame("RiftTextfield", name, parent or _context)
	--txt:SetText(text or "")
	return txt
end

function _g.Context.CreateButton(name, text, parent)
	local button = UI.CreateFrame("RiftButton", name, parent or _context)
	button:SetText(text)
	return button
end

function _g.Context.CreateTextureButton(name, normaltexture, overtexture, parent)
	return _g.TextureButton:new(name, normaltexture, overtexture, parent or _context)
end

function _g.Context.CreateTextInputDialog(name, text, width, height, parent)
	return _g.TextInputDialog:new(name, text, width, height, parent or _context)
end

function _g.Context.CreateDataGrid(name, width, height, parent)
	return _g.DataGrid:new(name, width, height, parent or _context)
end