local addon, _g = ...

_g.data = {
	shardName = Inspect.Shard().name,
	isDirty = false,
	allDataRows = {},
	filteredDataRows = {},
	totalItems = 0,
	shards = { "(All)" },
	dimensions = { "(All)" },
}

-- lookup table for dimension items
local _dimLookup = {}

-- server filter
local _serverFilter = nil

-- filter for dimension name
local _dimFilter = nil

-- filter for item name
local _textFilter = nil

-- filter target
local _filterTarget = nil

-- min ratio to discover a match
local MinMatchRatio = 0.70

function table:getOrAdd(k, func)
	if not self then
		error("table required")
	end
	
	local val = self[k]
	if not val then
		if func then
			val = func()
		else
			val = {}
		end
		
		self[k] = val
	end
	
	return val
end

function table:keys(t)
	if not self then
		error("the table cannot be nil")
	end
	
	local ret = {}
	for k, v in pairs(self) do
		table.insert(ret, k)
	end
	
	return ret
end

function table:contains(val)
	for i, v in ipairs(self) do
		if v == val then
			return true
		end
	end
	
	return false
end

local addDataRow = function(itemData, server, dimensionName)
	local rowData = {
			name = itemData.name,
			count = #itemData.instances,
			dimension = dimensionName,
			server = server
		}
	table.insert(_g.data.allDataRows, rowData)
	_g.data.totalItems = _g.data.totalItems + #itemData.instances
end

local TV = function(d)
	return tostring(math.floor(d * 10000))
end

local addLookupItemFromSave = function(serverName, dimensionType, itemType, instance, dimensionIdentifier)
	local serverMap = table.getOrAdd(_dimLookup, serverName)
	local dimensionTypeMap = table.getOrAdd(serverMap, dimensionType)
	local itemTypeMap = table.getOrAdd(dimensionTypeMap, itemType)
	local xmap = table.getOrAdd(itemTypeMap, TV(instance.x))
	local ymap = table.getOrAdd(xmap, TV(instance.y))
	local zmap = table.getOrAdd(ymap, TV(instance.z))
	local smap = table.getOrAdd(zmap, TV(instance.s))
	smap[TV(instance.yaw)] = dimensionIdentifier
end

local addLookupItemFromItemDetail = function(serverName, dimensionType, detail, dimensionIdentifier)
	local serverMap = table.getOrAdd(_dimLookup, serverName)
	local dimensionTypeMap = table.getOrAdd(serverMap, dimensionType)
	local itemTypeMap = table.getOrAdd(dimensionTypeMap, detail.type)
	local xmap = table.getOrAdd(itemTypeMap, TV(detail.coordX))
	local ymap = table.getOrAdd(xmap, TV(detail.coordY))
	local zmap = table.getOrAdd(ymap, TV(detail.coordZ))
	local smap = table.getOrAdd(zmap, TV(detail.scale))
	smap[TV(detail.yaw)] = dimensionIdentifier
end

local addSaveItemFromItemDetail = function(dimensionRoot, detail)
	local typeData = table.getOrAdd(dimensionRoot.items, detail.type, function() return { instances = {}, name = detail.name } end)
	table.insert(
		typeData.instances,
		{
			x = detail.coordX,
			y = detail.coordY,
			z = detail.coordZ,
			s = detail.scale,
			yaw = detail.yaw
		})
end

local sortGridDataTable = function()
	table.sort(
		_g.data.allDataRows,
		function (a, b) return a.name < b.name end )
end

local loadData = function()
	dimLookup = {}
	_g.data.shards = { "(All)" }
	_g.data.dimensions = { "(All)" }
	
	for serverName, serverData in pairs(DimensionInventorySave) do
		table.insert(_g.data.shards, serverName)
		for dimensionType, dimensionArray in pairs(serverData) do
			for _, dimensionInstance in ipairs(dimensionArray) do
				table.insert(_g.data.dimensions, dimensionInstance.name)
				for itemType, itemInstanceData in pairs(dimensionInstance.items) do
					addDataRow(itemInstanceData, serverName, dimensionInstance.name)
					for _, instance in ipairs(itemInstanceData.instances) do
						addLookupItemFromSave(serverName, dimensionType, itemType, instance, dimensionInstance.name)
					end
				end
			end
		end
	end
	
	table.sort(_g.data.shards)
	table.sort(_g.data.dimensions)
	
	_g.data.filteredDataRows = _g.data.allDataRows
	sortGridDataTable()
end

local findItem = function(shard, dimType, detail)
	if not detail then
		return nil
	end
	
	local serverMap = _dimLookup[shard]
	if not serverMap then 
		return nil
	end
	
	local dimensionTypeMap = serverMap[dimType]
	if not dimensionTypeMap then
		return nil
	end
	
	local itemTypeMap = dimensionTypeMap[detail.type]
	if not itemTypeMap then
		return nil
	end
	
	local xmap = itemTypeMap[TV(detail.coordX)]
	if not xmap then
		return nil
	end
	
	local ymap = xmap[TV(detail.coordY)]
	if not ymap then
		return nil
	end
	
	local zmap = ymap[TV(detail.coordZ)]
	if not zmap then
		return nil
	end
	
	local smap = zmap[TV(detail.scale)]
	if not smap then
		return nil
	end
	
	return smap[TV(detail.yaw)]
end

local passesServerFilter = function(server)
	return not _serverFilter or _serverFilter == server or _serverFilter == "(All)"
end

local passesDimensionFilter = function(dimension)
	return not _dimFilter or _dimFilter == dimension or _dimFilter == "(All)"	
end

local passesTextFilter = function(name)
	if not _textFilter or _textFilter == "" then
		return true
	end
	
	local status, result = pcall(
		function() 
			-- use plain text matching
			return string.find(name:lower(), _textFilter, 1, true) 
		end)
	if not status then
		--print(result)
		-- exception occurred in string.find
		return false
	end
	
	return result
end

local _filterCR = nil
local filterGridDataTable = function()
	_g.data.filteredDataRows = {}
	_filterCR = coroutine.create(
		function() 
			for _, rowData in ipairs(_g.data.allDataRows) do
				if passesServerFilter(rowData.server) and passesDimensionFilter(rowData.dimension) and passesTextFilter(rowData.name) then
					table.insert(_g.data.filteredDataRows, rowData)
				end
			end
		end)
	coroutine.resume(_filterCR)
end

local removeDataRowsByDimensionId = function(dimensionId)
	for i = #_g.data.allDataRows, 1, -1 do
		local row = _g.data.allDataRows[i]
		if row.dimension == dimensionId then
			table.remove(_g.data.allDataRows, i)
			_g.data.totalItems = _g.data.totalItems - row.count
		end
	end

	for i = #_g.data.filteredDataRows, 1, -1 do
		local row = _g.data.filteredDataRows[i]
		if row.dimension == dimensionId then
			table.remove(_g.data.filteredDataRows, i)
		end
	end
end

local function removeWhereValueIs(t, val)
	for k, v in pairs(t) do
		if v == val then
			t[k] = nil
		elseif type(v) == "table" then
			removeWhereValueIs(v, val)
		end
	end
end

local updateUIComponents = function()
	_g.btnToggle:UpdateTextures()
	_g.dataGrid:refresh()
end

local removeLookupDataByDimensionId = function(dimensionId)
	removeWhereValueIs(_dimLookup, dimensionId)
end

local removeSaveDataByDimensionId = function(dimensionId)
	-- find the dim data 
	for shard, dimTypeMap in pairs(DimensionInventorySave) do
		for dimTypeName, dimInstanceArray in pairs(dimTypeMap) do
			for i = #dimInstanceArray, 1, -1 do
				local dimInstance = dimInstanceArray[i]
				if dimInstance.name == dimensionId then
					-- found the dimension, remove the lookup items
					table.remove(dimInstanceArray, i)
					
					-- can only be one with this particular id, so break out
					return
				end
			end
		end
	end
	
	updateUIComponents()
end

function _g.data.onLoad()
	if not DimensionInventorySave then
		return
	end
	
	local cr = coroutine.create(
		function ()
			Command.System.Watchdog.Quiet()
			loadData()
			_g.dataGrid:LoadSelectBoxes()
		end)
	coroutine.resume(cr)
end

function _g.data.findCurrentDimension()
	local list = Inspect.Dimension.Layout.List()
	if not list then
		return nil
	end
	
	Command.System.Watchdog.Quiet()
	local shard = Inspect.Shard().name
	local dimensionType = Inspect.Unit.Detail("player").locationName
	local candidates = {}
	local totalItems = 0
	
	for itemId, _ in pairs(list) do 
		local detail = Inspect.Dimension.Layout.Detail(itemId)
		if detail then
			totalItems = totalItems + 1
			
			local dimInstanceId = findItem(shard, dimensionType, detail)
			if dimInstanceId then
				candidates[dimInstanceId] = (candidates[dimInstanceId] or 0) + 1
			end
		end
	end

	local maxCount = 0
	local maxDim = nil
	for dim, count in pairs(candidates) do
		if count > maxCount then
			maxCount = count
			maxDim = dim
		end
	end
	
	if (maxCount / totalItems) > MinMatchRatio then
		return maxDim
	end
	
	return nil
end

function _g.data.addDimension(dimensionIdentifier)
	if not dimensionIdentifier then
		return 
	end
	
	local items = Inspect.Dimension.Layout.List()
	if not items then
		return
	end
	
	local shard = Inspect.Shard().name
	local dimensionType = Inspect.Unit.Detail("player").locationName
	local serverMap = table.getOrAdd(DimensionInventorySave, shard)
	local dimensionArray = table.getOrAdd(serverMap, dimensionType)
	local dimensionData = { items = {}, name = dimensionIdentifier }
	table.insert(dimensionArray, dimensionData)
	
	if not table.contains(_g.data.shards, shard) then
		table.insert(_g.data.shards, shard)
		table.sort(_g.data.shards)
	end
	table.insert(_g.data.dimensions, dimensionIdentifier)
	table.sort(_g.data.dimensions)
	
	-- add rows to lookup and save data
	for itemId, _ in pairs(items) do
		local detail = Inspect.Dimension.Layout.Detail(itemId)
		if detail then
			addLookupItemFromItemDetail(shard, dimensionType, detail, dimensionIdentifier)
			addSaveItemFromItemDetail(dimensionData, detail)
		end
	end
	
	-- add the data rows
	for _, itemData in pairs(dimensionData.items) do
		addDataRow(itemData, shard, dimensionIdentifier)
	end
	
	_g.data.currentDimension = dimensionIdentifier
	-- sort the data rows
	sortGridDataTable()
	filterGridDataTable()
	updateUIComponents()
	_g.dataGrid:LoadSelectBoxes()
end

function _g.data.removeDimension(dimensionIdentifier)
	if not dimensionIdentifier then
		dimensionIdentifier = _g.data.findCurrentDimension()
		_g.data.currentDimension = nil
	end
	
	if not dimensionIdentifier then
		return
	end
	
	if dimensionIdentifier == _g.data.currentDimension then
		_g.data.currentDimension = nil
	end
	
	Command.System.Watchdog.Quiet()
	removeDataRowsByDimensionId(dimensionIdentifier)
	removeLookupDataByDimensionId(dimensionIdentifier)
	removeSaveDataByDimensionId(dimensionIdentifier)
	for i, v in ipairs(_g.data.dimensions) do
		if v == dimensionIdentifier then
			table.remove(_g.data.dimensions, i)
		end
	end
	
	updateUIComponents()
	_g.dataGrid:LoadSelectBoxes()
end

local _refreshCR = nil
function _g.data.refresh()
	_g.btnToggle:UpdateTextures()
	if _refreshCR and coroutine.status(_refreshCR) ~= "dead" then
		return
	end

	local locationName = Inspect.Unit.Detail("player").locationName
	if not locationName then
		updateUIComponents()
		return
	elseif not string.find(locationName, "Dimension: ") then	
		updateUIComponents()
		return
	end
	
	
	if _g.data.isDirty then
		_refreshCR = coroutine.create(
			function()
				Command.System.Watchdog.Quiet()
				if not _g.data.currentDimension then
					_g.data.currentDimension = _g.data.findCurrentDimension()
					if not _g.data.currentDimension then
						updateUIComponents()
						return
					end
				end

				local dimName = _g.data.currentDimension
				_g.data.removeDimension(dimName)
				_g.data.addDimension(dimName)
			end)
		coroutine.resume(_refreshCR)
	end
end

function _g.data.filter(shard, dimension, filter)
	if _filterCR and coroutine.status(_filterCR) ~= "dead" then
		return
	end

	_serverFilter = shard
	_dimFilter = dimension
	if filter then
		_textFilter = filter:lower()
	else
		_textFilter = nil
	end
	filterGridDataTable()
	updateUIComponents()
end

function _g.data.saveButtonPosition(name, x, y)
	if not DIUISave.buttons then
		DIUISave.buttons = {}
	end
	
	DIUISave.buttons[name] = { x = x, y = y }
end

function _g.data.getButtonPosition(name)
	if not DIUISave.buttons then
		DIUISave.buttons = {}
	end
	
	return DIUISave.buttons[name]
end

function _g.data.resetUI()
	DIUISave = {}
	DIUISave.buttons = {}
end