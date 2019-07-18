local addon, _g = ...

local hook = function(event, callback)
	Command.Event.Attach(event, callback, tostring(callback))
end

local unhook = function(event, callback)
	Command.Event.Detach(event, callback, tostring(callback))
end

local tick = Inspect.Time.Real()


local Callback = {}

function Callback:dim_item_add(addedItem)
	_g.data.isDirty = true
end

function Callback:dim_item_remove(removedItem)
	_g.data.isDirty = true
end

function Callback:var_save_begin()
	DimensionInventory = DimensionInventorySave
end

function Callback:var_load_end()
	DimensionInventorySave = DimensionInventory or {}
end

function Callback:update_end()
	local now = Inspect.Time.Real()
	if now - tick < 2 then
		return
	end
	
	tick = now
	_g.data.refresh()
	_g.btnToggle:UpdateTextures()
end


function Callback:addon_loaded()
	_g.btnList = _g.Context.CreateTextureButton(
		"btnList",
		"img/btn_dimensions_top_manage_(normal).png",
		"img/btn_dimensions_top_manage_(over).png")
	
	_g.btnList:SetPoint("BOTTOMRIGHT", UI.Native.MapMini, "BOTTOMRIGHT", -10, -10)
	function _g.btnList:LeftClick()
		if DimensionInventorySave and next(DimensionInventorySave) then
			_g.dataGrid:SetVisible(true)
		end
	end
end

function Callback:player_available(list)
	for k, specifier in pairs(list) do
		if specifier == "player" then
			-- player is available so we can determine the zone
			_g.data.onLoad()
			_g.dataGrid:onLoad()
			_g.btnToggle:UpdateTextures()
		end
	end
end

if Command then
	hook(Event.Dimension.Layout.Add, Callback.dim_item_add)
	hook(Event.Dimension.Layout.Remove, Callback.dim_item_remove)
	hook(Event.Addon.SavedVariables.Save.Begin, Callback.var_save_begin)
	hook(Event.Addon.SavedVariables.Load.End, Callback.var_load_end)
	hook(Event.System.Update.End, Callback.update_end)
	hook(Event.Addon.Load.End, Callback.addon_loaded)
	hook(Event.Unit.Availability.Full, Callback.player_available)
end
