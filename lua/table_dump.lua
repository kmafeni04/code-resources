---@class TableDump
--- The table_dump module
local table_dump = {}
--[[
  Returns the contents of a table as a string
  Usage:
  ```lua
  local table_dump = require("table_dump")
  local tbl = { [1] = 10, hello = 1 }
  print(table_dump.tostring(tbl))
  --> Prints { [1] = 10, ["hello"] = 1, }
  ```
]]
---@param tbl table
---@return string
function table_dump.tostring(tbl)
  assert(type(tbl) == "table", "Param `tbl` must be of type `table`")
  if not next(tbl) then
    return "{}"
  end
  local str = "{ "
  for key, value in pairs(tbl) do
    if type(value) == "table" then
      value = table_dump.tostring(value)
    elseif type(value) == "string" then
      print(value:find("\n"))
      if value:match("\n") then
        value = "[[" .. value .. "]]"
      else
        value = [["]] .. value .. [["]]
      end
    end
    if type(key) ~= "number" then
      key = '"' .. key .. '"'
    end
    str = str .. "[" .. key .. "] = " .. tostring(value) .. ", "
  end
  return str .. "}"
end

--[[
  Returns the contents of a table as a pretty string
  Usage:
  ```lua
  local table_dump = require("table_dump")
  local tbl = { [1] = 10, hello = 1 }
  print(table_dump.pretty_tostring(tbl))
  --> Prints
  {
    [1] = 10,
    ["hello"] = 1,
  }
  ```
]]
---@param tbl table
---@param indent integer?
---@return string
function table_dump.pretty_tostring(tbl, indent)
  assert(type(tbl) == "table", "Param `tbl` must be of type `table`")
  if not next(tbl) then
    return "{}"
  end
  indent = indent or 0
  assert(type(indent) == "number", "Param `indent` must be of type `number`")
  local indent_str = "  "
  local str = "{\n" .. string.rep(indent_str, indent + 1)
  for key, value in pairs(tbl) do
    if type(value) == "table" then
      value = table_dump.pretty_tostring(value, indent + 1)
    elseif type(value) == "string" then
      if value:match("\n") then
        value = "[[" .. value .. "]]"
      else
        value = [["]] .. value .. [["]]
      end
    end
    if type(key) ~= "number" then
      key = '"' .. key .. '"'
    end
    str = str .. "[" .. key .. "] = " .. tostring(value) .. ",\n" .. string.rep(indent_str, indent + 1)
  end
  return str:sub(1, #str - #indent_str) .. "}"
end

return table_dump
