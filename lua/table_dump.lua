--[[
  Returns the contents of a table as a string
  Usage:
  ```lua
  local table_dump = require("table_dump")
  local tbl = { [1] = 10, hello = 1 }
  print(table_dump(tbl))
  --> Prints { [1] = 10, ["hello"] = 1, }
  ```
]]
---@param tbl table
---@return string
local function table_dump(tbl)
  local str = "{ "
  for key, value in pairs(tbl) do
    if type(value) == "table" then
      value = table_dump(value)
    end
    if type(value) == "string" then
      value = [["]] .. value .. [["]]
    end
    if type(key) ~= "number" then
      key = '"' .. key .. '"'
    end
    str = str .. "[" .. key .. "] = " .. tostring(value) .. ", "
  end
  return str .. " }"
end

return table_dump
