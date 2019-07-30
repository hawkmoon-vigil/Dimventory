local addon, _g = ...

function _g.print(s)
	Command.Console.Display("general", true, "<font color=\"#00FF00\"> Dimventory: " .. tostring(s) .. "</font>", true)
end

function _g.printError(s)
	Command.Console.Display("general", true, "<font color=\"#FF0000\"> Dimventory ERROR: " .. tostring(s) .. "</font>", true)
end

local commandHandler = function(val)
	if val == "find" then
		_g.print(_g.data.findCurrentDimension() or "not found")
	elseif val == "reset" then
		DimensionInventorySave = { }
		_g.data.onLoad()
		_g.print("dimventory data reset")
	elseif  val == "resetui" then
		_g.data.resetUI()
		_g.btnToggle:SetInitialPosition()
		_g.btnList:SetInitialPosition()
	elseif val:find("remove ") then
		local toRemove = val:sub(8,-1)
		_g.print("removing dimension " .. toRemove)
		_g.data.removeDimension(toRemove)
		_g.dataGrid:onLoad()
		_g.btnToggle:UpdateTextures()
	else
		_g.printError("command line options:")
		_g.printError("  reset                  - removes all local data and resets dimension tracking")
		_g.printError("  remove &lt;dimname&gt; - removes a dimension from the tracked list")
	end
end

table.insert(Command.Slash.Register("dimventory"), { commandHandler, "Dimventory", "" })
