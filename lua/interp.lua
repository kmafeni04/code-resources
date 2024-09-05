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
  Works with expressions and table fields
  ```lua
  local tbl = { a = 1 }
  print(interp("The value of tbl.a + 1 is {{tbl.a + 1}}"))
  --> Prints "The value of tbl.a + 1 is 2"
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
      variables[key] = value
    end
    idx = idx + 1
  until key == nil

  for key, value in pairs(_G) do
    variables[key] = value
  end

  local function eval(expr)
    local func, _ = load("return " .. expr, nil, nil, variables)
    if func then
      local success, result = pcall(func)
      if success then
        return tostring(result)
      end
    end
  end

  local new_str = str:gsub("{{(.-)}}", function(expr)
    return eval(expr:match("^%s*(.-)%s*$"))
  end)

  if new_str ~= "nil" then
    return new_str
  else
    return str
  end
end

return interp
