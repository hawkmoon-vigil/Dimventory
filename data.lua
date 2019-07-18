local addon, _g = ...

_g.data = {
	shardName = Inspect.Shard().name,
	isDirty = false
}

local serverFilter = nil
local dimFilter = nil
local textFilter = nil

local itemLookup = nil
local MinMatchPercentage = 0.70

function orderItemsByName(item1, item2)
	return item1.itemName < item2.itemName
end

function _g.data.addDimension(dimensionName)
	local cr = coroutine.create(function ()
		local zoneItems = Inspect.Dimension.Layout.List()
		
		if not dimensionName or dimensionName == "" then
			_g.printError("Failed to add dimesion. The name cannot be blank.")
			return
		end
		
		if not DimensionInventorySave[_g.data.shardName] then
			DimensionInventorySave[_g.data.shardName] = {}
		end

		if not DimensionInventorySave[_g.data.shardName][_g.data.locationName] then
			DimensionInventorySave[_g.data.shardName][_g.data.locationName] = {}
		end
		
		local dimData = {
			name = dimensionName,
			items = {}
		}
		
		table.insert(DimensionInventorySave[_g.data.shardName][_g.data.locationName], dimData)
		
		local dimensionItems = dimData.items
		for itemId, _ in pairs(zoneItems) do
			local item = Inspect.Dimension.Layout.Detail(itemId)
			if item then
				if not dimensionItems[item.type] then
					dimensionItems[item.type] = 
					{ 
						name = item.name,
						instances = {  }
					}
				end

				table.insert(dimensionItems[item.type].instances, 
					{ 
						x = item.coordX, 
						y = item.coordY, 
						z = item.coordZ,
						yaw = item.yaw, 
						s = item.scale
					})
			end
		end
		
		_g.data.onLoad()
		_g.data.filter(serverFilter, dimFilter, textFilter)
		_g.btnToggle:UpdateTextures()
		_g.data.isDirty = true
	end)
	coroutine.resume(cr)
end

function addItemToLookup(server, dimType, loc, typeId, dimName)
	if not server or not dimType or not loc or not typeId or not dimName then
		error("expected server, dimType, loc, type id, and name")
	end
	
	local xval = tostring(math.floor(loc.x * 10000))
	local yval = tostring(math.floor(loc.y * 10000))
	local zval = tostring(math.floor(loc.z * 10000))
	local sval = tostring(math.floor(loc.s * 10000))
	local yawval = tostring(math.floor(loc.yaw * 10000))
	
	if not itemLookup[server] then
		itemLookup[server] = {}
	end
	
	if not itemLookup[server][dimType] then
		itemLookup[server][dimType] = {}
	end

	if not itemLookup[server][dimType][xval] then
		itemLookup[server][dimType][xval] = {}
	end
	
	if not itemLookup[server][dimType][xval][yval] then
		itemLookup[server][dimType][xval][yval] = {}
	end

	if not itemLookup[server][dimType][xval][yval][zval] then
		itemLookup[server][dimType][xval][yval][zval] = {}
	end
		
	if not itemLookup[server][dimType][xval][yval][zval][sval] then
		itemLookup[server][dimType][xval][yval][zval][sval] = {}
	end

	if not itemLookup[server][dimType][xval][yval][zval][sval][yawval] then
		itemLookup[server][dimType][xval][yval][zval][sval][yawval] = {}
	end
	
	if not itemLookup[server][dimType][xval][yval][zval][sval][yawval][typeId] then
		itemLookup[server][dimType][xval][yval][zval][sval][yawval][typeId] = {}
	end
	
	itemLookup[server][dimType][xval][yval][zval][sval][yawval][typeId] = dimName
end

function _g.data.dumpItemLookup()
	dump(itemLookup)
end

function _g.data.onLoad()
	local rowData = {}
	itemLookup = {}
	_g.totalItems = 0
	
	for server, dimensions in pairs(DimensionInventorySave) do
		for dimType, dimArray in pairs(dimensions) do
			for _, dim in ipairs(dimArray) do
				for typeId, typeData in pairs(dim.items) do
					table.insert(
						rowData, 
						{ 
							itemName = typeData.name, 
							count = #typeData.instances, 
							server = server, 
							dimension = dim.name, 
						})
					
					_g.totalItems = _g.totalItems + #typeData.instances
					
					for _, loc in ipairs(typeData.instances) do
						if loc then
							addItemToLookup(server, dimType, loc, typeId, dim.name)
						end
					end
				end
			end
		end
	end 
	
	table.sort(rowData, orderItemsByName)
	
	_g.allDataRows = rowData
	_g.dataRows = rowData
end	

function table.clone(org)
  return {table.unpack(org)}
end

local currentItem = nil

function filter()
	return string.find(currentItem, textFilter)
end

function _g.data.filter(server, dimension, text)
	serverFilter = server
	dimFilter = dimension

	if not server and not dimension and not text then
		_g.dataRows = _g.allDataRows
		return
	end

	textFilter = text:lower()
	
	local filtered = table.clone(_g.allDataRows)
	if text and text ~= "" then
		for i = #filtered, 1, -1 do
			currentItem = filtered[i].itemName:lower()
			
			local succeeded, res = pcall(filter)
			if succeeded and not res then
				table.remove(filtered, i)
			end
		end
	end

	if dimension and dimension ~= "" and dimension ~= "(All)" then
		for i = #filtered, 1, -1 do
			if filtered[i].dimension ~= dimension then
				table.remove(filtered, i)
			end
		end
	end
	
	if server and server ~= "" and server ~= "(All)" then
		for i = #filtered, 1, -1 do
			if not string.find(filtered[i].server, server) then
				table.remove(filtered, i)
			end
		end
	end
	
	_g.dataRows = filtered
end

function _g.data.removeDimension(dimName)
	if dimName == _g.data.currentDimension then
		_g.data.currentDimension = nil
	end

	for _, dimDict in pairs(DimensionInventorySave) do
		for _, dimArray in pairs(dimDict) do 
			for i = #dimArray, 1, -1 do
				local v = dimArray[i]
				if v.name == dimName then
					table.remove(dimArray, i)
					
				end
			end
		end
	end
end

function _g.data.removeCurrentDimension()
	local arr = DimensionInventorySave[_g.data.shardName][_g.data.locationName]
	for i, v in ipairs(arr) do
		if v.name == _g.data.currentDimension then
			table.remove(arr, i)
			_g.data.currentDimension = nil
			return
		end
	end
end

local TF = function(i)
	return tostring(math.floor(i * 10000))
end

function _g.data.findDimName()
	local zoneItems = Inspect.Dimension.Layout.List()
	if not zoneItems or not next(zoneItems) then
		_g.data.currentDimension = nil
		return nil
	end
	
	if not itemLookup then
		return nil
	end
	
	local candidates = {}
	local shardData = itemLookup[_g.data.shardName]
	if not shardData then 
		_g.data.currentDimension = nil
		return nil
	end
	
	local xmap = shardData[_g.data.locationName]
	if not xmap then
		_g.data.currentDimension = nil
		return nil
	end
	
	local matchCount = 0
	local totalItems = 0

	for itemId, _ in pairs(zoneItems) do 
		local detail = Inspect.Dimension.Layout.Detail(itemId)
		if detail then
			totalItems = totalItems + 1
			local ymap = xmap[TF(detail.coordX)]
			if ymap then
				local zmap = ymap[TF(detail.coordY)]
				if zmap then
					local smap = zmap[TF(detail.coordZ)]
					if smap then
						local yawmap = smap[TF(detail.scale)]
						if yawmap then
							local typeMap = yawmap[TF(detail.yaw)]
							if typeMap then
								local name = typeMap[detail.type]
								candidates[name] = (candidates[name] or 0) + 1
							end
						end
					end
				end
			end
		end
	end
	
	
	local foundDim = nil
	local foundTotal = 0
	for k, v in pairs(candidates) do
		if v > foundTotal then
			foundDim = k
			foundTotal = v
		end
	end
	
	if (foundTotal / totalItems) > MinMatchPercentage then
		_g.data.currentDimension = foundDim
		return foundDim
	else
		_g.data.currentDimension = nil
		return nil
	end
end

function _g.data.refresh()
	_g.data.locationName = Inspect.Unit.Detail("player").locationName
	_g.data.shardName = Inspect.Shard().name
	if _g.data.isDirty then
		local cr = coroutine.create(function()
			_g.data.currentDimension = _g.data.findDimName()
			if not _g.data.currentDimension then
				_g.data.isDirty = false
				return
			end
			
			local shardData = DimensionInventorySave[_g.data.shardName]	
			if not shardData then
				_g.data.isDirty = false
				_g.print("no shard data")
				return
			end
				
			local dimArray = DimensionInventorySave[_g.data.shardName][_g.data.locationName]
			if dimType then
				for i, dimInstance in ipairs(dimArray) do
					if dimInstance.name == _g.data.currentDimension then
						table.remove(dimArray, i)
						_g.data.addDimension(dimName)
						break
					end
				end
			 end

			_g.data.isDirty = false
			_g.dataGrid:refresh()
		end)
		coroutine.resume(cr)
	elseif not _g.data.currentDimension then
		local cr = coroutine.create(function()
			_g.data.currentDimension = _g.data.findDimName()
		end)
		
		coroutine.resume(cr)
	end
end