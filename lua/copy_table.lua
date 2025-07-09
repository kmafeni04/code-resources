--[[
	Copies a table and returns it's value
	The copied table does not link to the original in memory

	Usage:
  ```lua
  local tbl1 = { hello = "world" }
  local tbl2 = copy_table(tbl1)
  tbl1.see_you = "later"
  print(tbl1.see_you)
  --> Prints "later"
  print(tbl2.see_you)
  --> Prints "nil"
  ```
]]
---@param tbl table
---@return table
local function copy_table(tbl)
  local copy = {}
  for key, value in pairs(tbl) do
    if type(value) == "table" then
      copy[key] = copy_table(value)
    else
      copy[key] = value
    end
  end
  return copy
end

return copy_table
