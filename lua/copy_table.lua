--- Copies a table and returns it's value
--- The copied table does not link to the original in memory
---@param tbl table
---@return table
local function copy_table(tbl)
	local copy = {}
	for key, value in pairs(tbl) do
		if type(key) == "table" then
			copy[key] = copy_table(key)
		end
		copy[key] = value
	end
	return copy
end

return copy_table
