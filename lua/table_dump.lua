---Returns the contents of a table as a string
---@param tbl table
---@return string
local function table_dump(tbl)
  local str = "{ "
  for key, value in pairs(tbl) do
    if type(value) == "table" then
      value = table_dump(value)
    end
    if type(key) ~= "number" then
      key = '"' .. key .. '"'
    end
    str = str .. "[" .. key .. "] = " .. tostring(value) .. ", "
  end
  return str .. "}"
end

return table_dump
