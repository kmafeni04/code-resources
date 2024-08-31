--[[
  Replaces `{{VAR}}` in the provided string with the value of it's corresponding variable if present
  Usage:
  ```lua
  local val = "hello world"
  print(interp("The value of val is {{val}}"))
  --> Prints "The value of val is hello world"
  ```
  if the variable isn't present:
  ```lua
  print(interp("The {{no_var}} variable isn't present"))
  --> Prints "The {{no_var}} variable isn't present"
  ```
  Note:
  This only works with variables
  If you would like to use table fields or the returns of a function, assign them to a variable
  ```lua
  local tbl = { val = 1 }
  local tbl_val = tbl.val
  print(interp("{{tbl_val}}"))
  --> Prints "1"
  ```
]]
---@param str string
---@return string
local function interp(str)
  local variables = {}
  local idx = 1

  repeat
    local key, value = debug.getlocal(2, idx)
    if key ~= nil then
      variables[key] = tostring(value)
    end
    idx = idx + 1
  until key == nil
  for key, value in pairs(_G) do
    variables[key] = value
  end

  for word in str:gmatch("{{%s*([%w_]+)%s*}}") do
    if variables[word] then
      str = str:gsub("{{%s*(" .. word .. ")%s*}}", variables[word], 1)
    end
  end
  return str
end

return interp
