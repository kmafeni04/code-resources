---@class Cases
---@field default? fun():...?
---@field [string] fun():...?

--[[
  Implements switch cases

  Usage: 
  ```lua
  local expr = "value"
  local val = switch(expr, {
    value = function() return "A value" end,
    default = function() return "Default value" end
  })
  print(val)
  --> Prints "A value"
  ```  
  When `expr` doesn't match a case:
  ```lua
  local expr = "won't match"
  local val = switch(expr, {
    value = function() return "A value" end,
    default = function() return "Default value" end
  })
  print(val)
  --> Prints "Default value"
  ```  
  When `expr` doesn't match a case and `default` is not provided:
  ```lua
  local expr = "won't match"
  local val = switch(expr, {
    value = function() return "A value" end,
  })
  print(val)
  --> Prints nil
  ```  
  ]]
---@param expr any
---@param cases Cases
---@return ...?
local function switch(expr, cases)
  if type(expr) == "function" then
    expr = expr()
  end
  if not cases[expr] and cases["default"] then
    return cases["default"]()
  elseif cases[expr] then
    return cases[expr]()
  else
    return nil
  end
end

return switch
