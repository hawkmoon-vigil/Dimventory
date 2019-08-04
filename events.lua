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
	DIUI = DIUISave
end

function Callback:var_load_end()
	DimensionInventorySave = DimensionInventory or {}
	DIUISave = DIUI or {}
	_g.btnToggle:SetInitialPosition()
	_g.btnList:SetInitialPosition()
end

function Callback:update_end()
	local now = Inspect.Time.Real()
	if now - tick < 2 then
		return
	end
	
	tick = now
	_g.data.refresh()
end

function Callback:addon_loaded(identifier)
	if identifier ~= addon.identifier then
		return
	end
	
	_g.data.onLoad()
end

function Callback:unit_full_availability(map)
	for id, specifier in pairs(map) do
		if specifier == "player" then
			_g.data.currentDimension = nil
		end
	end
end

hook(Event.Dimension.Layout.Add, Callback.dim_item_add)
hook(Event.Dimension.Layout.Remove, Callback.dim_item_remove)
hook(Event.Addon.SavedVariables.Save.Begin, Callback.var_save_begin)
hook(Event.Addon.SavedVariables.Load.End, Callback.var_load_end)
hook(Event.System.Update.End, Callback.update_end)
hook(Event.Addon.Load.End, Callback.addon_loaded)
hook(Event.Unit.Availability.Full, Callback.unit_full_availability)
