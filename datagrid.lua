local addon, _g = ...

_g.DataGrid = _g.Class:new()

function _g.DataGrid:Init(name, width, height, context)
	self._frame = UI.CreateFrame("SimpleWindow", name, context)
	self._frame:SetCloseButtonVisible(true)
	self._frame:SetWidth(width)
	self._frame:SetHeight(height)
	self._frame.parent = self
	function self._frame.Event:Close()
		-- switch the focus of the keys to global ui window so that the input text box isn't written
		-- to after the window is closed
		self.parent._txtFilter:SetKeyFocus(false)
		self.parent._serverSelect.dropdown:SetVisible(false)
		self.parent._dimensionSelect.dropdown:SetVisible(false)
	end
	
	self._lblServer = _g.Context.CreateLabel("Server", "Server", self._frame)
	self._lblServer:SetPoint("TOPLEFT", self._frame, "TOPLEFT", 40, 60)

	self._serverSelect = UI.CreateFrame("SimpleSelect", "serverSelect", self._frame)
	self._serverSelect:SetPoint("TOPLEFT", self._lblServer, "BOTTOMLEFT", 0, 4)
	self._serverSelect:SetWidth(150)
	self._serverSelect.parent = self

	self._lblDimension = _g.Context.CreateLabel("Dimension", "Dimension", self._frame)
	self._lblDimension:SetPoint("TOPLEFT", self._lblServer, "TOPLEFT", 200, 0)
	
	function self._serverSelect.Event:ItemSelect(item, value, index)
		--dump("item selected" .. item .. " " .. value .. " " .. tostring(index))
		local dims = { "(All)" }
		
		if value ~= "(All)" then
			for _, data in pairs(DimensionInventorySave[value]) do
				for _, instance in ipairs(data) do
					table.insert(dims, instance.name)
				end
			end
			_g.data.filter(value, nil, self.parent._txtFilter:GetText())
			self.parent._pageNumber = 1
		end
		
		table.sort(dims)
		self.parent._dimensionSelect:SetItems(dims, dims)
		self.parent._grid:refresh()
	end
	
	self._dimensionSelect = UI.CreateFrame("SimpleSelect", "dimensionSelect", self._frame)
	self._dimensionSelect:SetPoint("TOPLEFT", self._lblDimension, "BOTTOMLEFT", 0, 4)
	self._dimensionSelect:SetWidth(150)
	self._dimensionSelect.parent = self
	function self._dimensionSelect.Event:ItemSelect(item, value, index)
		local server = self.parent._serverSelect:GetSelectedValue()
		_g.data.filter(server, value, self.parent._txtFilter:GetText())
		self.parent._pageNumber = 1
		self.parent._grid:refresh()
	end
	


	self._lblFilter = _g.Context.CreateLabel("Filter", "Filter", self._frame)
	self._lblFilter:SetPoint("TOPLEFT", self._lblDimension, "TOPLEFT", 200, 0)

	self._txtFilter = _g.Context.CreateTextBox("", "", self._frame)
	self._txtFilter:SetPoint("TOPLEFT", self._lblFilter, "BOTTOMLEFT", 0, 4)
	self._txtFilter:SetBackgroundColor(0, 0, 0, 1)	
	self._txtFilter.parent = self
	function self._txtFilter.Event:TextfieldChange()
		local server = self.parent._serverSelect:GetSelectedValue()
		local dimension = self.parent._dimensionSelect:GetSelectedValue()
		local filter = self:GetText()
		_g.data.filter(server, dimension, filter)
		self.parent._pageNumber = 1
		self.parent._grid:refresh()
	end

	self._lblItem = _g.Context.CreateLabel("Item", "Item", self._frame)
	self._lblItem:SetPoint("TOPLEFT", self._serverSelect, "BOTTOMLEFT", 0, 10)

	self._lblCount = _g.Context.CreateLabel("#", "#", self._frame)
	self._lblCount:SetPoint("TOPLEFT", self._lblItem, "TOPLEFT", 301, 0)

	self._lblServer = _g.Context.CreateLabel("Server", "Server", self._frame)
	self._lblServer:SetPoint("TOPLEFT", self._lblCount, "TOPLEFT", 51, 0)

	self._lblDimName = _g.Context.CreateLabel("Dimension", "Dimension", self._frame)
	self._lblDimName:SetPoint("TOPLEFT", self._lblServer, "TOPLEFT", 101, 0)
	
	self._grid = UI.CreateFrame("SimpleGrid", "data", self._frame)
	self._grid:SetPoint("TOPLEFT", self._lblItem, "BOTTOMLEFT", 0, 5)
	self._grid:SetCellPadding(1)
	self._grid.parent = self
	self._grid:SetColumnWidth(1, 300)
	self._grid:SetColumnWidth(2, 50)
	self._grid:SetColumnWidth(3, 100)
	self._grid:SetColumnWidth(4, 280)
	self._grid:SetRowBorder(1, 0.16, 0.16, 0.16, 1)
	self._grid:SetBorder(1, 0.16, 0.16, 0.16, 1)
	self._pageNumber = 1
	self._pageItemCount = 15

	self._btnLeft = _g.Context.CreateTextureButton(
		"btnLeft",
		"img/btn_arrow_L_(normal).png",
		"img/btn_arrow_L_(over).png", self._frame)
	self._btnLeft.parent = self
	
	self._btnLeft:SetPoint("TOPLEFT", self._grid, "BOTTOMLEFT", 0, 10)
	
	function self._btnLeft:LeftClick()
		self.parent._grid:PreviousPage()
	end

	self._btnRight = _g.Context.CreateTextureButton(
		"btnRight",
		"img/btn_arrow_R_(normal).png",
		"img/btn_arrow_R_(over).png", self._frame)
	self._btnRight.parent = self
	
	self._btnRight:SetPoint("TOPRIGHT", self._grid, "BOTTOMRIGHT", 0, 10)
	
	function self._btnRight:LeftClick()
		self.parent._grid:NextPage()
	end
	
	function self._grid.Event:WheelForward()
		self:PreviousPage()
	end
	
	function self._grid.Event:WheelBack()
		self:NextPage()
	end
	
	function self._grid:NextPage()
		local oldPage = self.parent._pageNumber
		self.parent._pageNumber = self.parent._pageNumber + 1
		local pageMax = math.ceil(#_g.dataRows / self.parent._pageItemCount)
		if self.parent._pageNumber > pageMax then
			self.parent._pageNumber = pageMax
		end
		
		if oldPage ~= self.parent._pageNumber then
			self:refresh()
		end
	end
	
	function self._grid:PreviousPage()
		local oldPage = self.parent._pageNumber
		self.parent._pageNumber = self.parent._pageNumber - 1
		if self.parent._pageNumber < 1 then
			self.parent._pageNumber = 1
		end
		
		if oldPage ~= self.parent._pageNumber then
			self:refresh()
		end
	end
	
	function self._grid:refresh()
		local startIndex = (self.parent._pageNumber - 1) * self.parent._pageItemCount + 1
		local endIndex = self.parent._pageNumber * self.parent._pageItemCount
		local total = #_g.dataRows;
		if endIndex > total then
			endIndex = total
		end
		self.parent:SetStatus(startIndex, endIndex, total)

		local rowIndex = 0
		for _, rowFrame in ipairs(self.rowFrames) do
			local colIndex = 1
			local rowData = _g.dataRows[startIndex + rowIndex]
			
			for _, cell in ipairs(rowFrame.cells) do
				if rowData then
					if colIndex == 1 then
						cell:SetText(rowData.itemName)
					elseif colIndex == 2 then
						cell:SetText(tostring(rowData.count))
					elseif colIndex == 3 then
						cell:SetText(rowData.server)
					elseif colIndex == 4 then
						cell:SetText(rowData.dimension)
					end
				else
					cell:SetText("")
				end

				colIndex = colIndex + 1
			end
			
			rowIndex = rowIndex + 1
		end
	end

	self._lblPage = _g.Context.CreateLabel("Status", "Status", self._frame)
	self._lblPage:SetPoint("TOPCENTER", self._grid, "BOTTOMCENTER", 0, 10)

	self._lblTotal = _g.Context.CreateLabel("Status", "Status", self._frame)
	self._lblTotal:SetPoint("TOPCENTER", self._lblPage, "BOTTOMCENTER", 0, 10)
end

function _g.DataGrid:refresh()
	self._grid:refresh()
end

function _g.DataGrid:new(name, width, height, context)
	local grid = _g.Class:new()
	setmetatable(grid, self)
	grid:Init(name, width, height, context)
	return grid
end


function _g.DataGrid:SetPoint(loc1, parent, loc2, offsetx, offsety)
	self._frame:SetPoint(loc1, parent, loc2, offsetx or 0, offsety or 0)
end

local createCell = function(name, frame)
	local label = _g.Context.CreateLabel(name, name, frame)
	label:SetBackgroundColor(0, 0, 0, 1)
	label:SetHeight(20)
	return label
end

function _g.DataGrid:createRow(row)
	local cells = {}
	table.insert(cells, createCell(row.itemName, self._grid))
	table.insert(cells, createCell(tostring(row.count), self._grid))
	table.insert(cells, createCell(row.server, self._grid))
	table.insert(cells, createCell(row.dimension, self._grid))
	return cells
end

local createBlankCell = function(frame)
	local label = _g.Context.CreateLabel("", "", frame)
	label:SetBackgroundColor(0, 0, 0, 1)
	label:SetHeight(20)
	return label
end

function _g.DataGrid:createBlankRow(row)
	local cells = {}
	table.insert(cells, createBlankCell(self._grid))
	table.insert(cells, createBlankCell(self._grid))
	table.insert(cells, createBlankCell(self._grid))
	table.insert(cells, createBlankCell(self._grid))
	return cells
end

function _g.DataGrid:SetStatus(startIndex, endIndex, total)
	self._lblPage:SetText(tostring(startIndex) .. "-" .. endIndex .. " of " .. tostring(total))
	self._lblTotal:SetText(tostring(_g.totalItems) .. " total items")
end

function _g.DataGrid:LoadServers()
	local servers = {
		"(All)"
	}
	
	for server, _ in pairs(DimensionInventorySave) do
		table.insert(servers, server)
	end
	
	table.sort(servers)
	
	local defaultDimensions = { "(All)" }
	self._serverSelect:SetItems(servers, servers)
	self._dimensionSelect:SetItems(defaultDimensions, defaultDimensions)
end

function _g.DataGrid:onLoad()
	local rowData = {}
	local startIndex = (self._pageNumber - 1) * self._pageItemCount + 1
	local endIndex = self._pageNumber * self._pageItemCount
	local total = #_g.dataRows
	
	if endIndex > total then 
		endIndex = total
	end

	self:SetStatus(startIndex, endIndex, total)
	
	--for i = startIndex, endIndex do
	--	local item = _g.dataRows[i]
	--	local row = self:createRow(item)
	--	table.insert(rowData, row)
	--end
	
	for i = 1, self._pageItemCount do
		table.insert(rowData, self:createBlankRow())
	end

	self._grid:SetRows(rowData)
	self:refresh()
	
	self:LoadServers()
end

function _g.DataGrid:SetVisible(value)
	self._frame:SetVisible(value)
end

_g.dataGrid = _g.Context.CreateDataGrid("", 800, 550)
_g.dataGrid:SetPoint("CENTER", UIParent, "CENTER")
_g.dataGrid:SetVisible(false)
