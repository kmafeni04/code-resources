---@alias PipeFunc fun(x: any): any
--[[
  Implements the "pipe operator" seen in functional languages, where the return of the previous function is the first parameter of the next

  Usage:
  ```lua
  local val = pipe("test", string.reverse, string.upper)
  print(val)
  --> Prints "TSET"
  ```
  
  If you would like to see what each function does to the parameter, you can set the debug boolean to true
  ```lua
  local val = pipe("test", true, string.reverse, string.upper)
  print(val)
  --> Prints "Return of function 1:
  --          tset
  --          
  --          Return of function 2:
  --          TSET
  --          
  --          TSET"
  ```
  Anonymous functions can also be written directly into the sequence as long as they take at least one parameter and have a return
  ```lua
  local val = pipe("hello", function(x) return x .. " world" end, string.upper)
  print(val)
  --> Prints "HELLO WORLD"
  ```
]]
---@param param any
---@param dbg boolean
---@param ... PipeFunc
---@return any
---@overload fun(param: any, ...: PipeFunc)
local pipe = function(param, dbg, ...)
  local current_param = param
  local funcs = { ... }
  if type(dbg) == "function" then
    table.insert(funcs, 1, dbg)
  end
  for key, func in pairs(funcs) do
    current_param = func(current_param)
    if dbg == true then
      print("Return of function " .. key .. ":")
      print(tostring(current_param))
      print()
    end
  end
  return current_param
end

local val = pipe(1, true, tostring, function(x)
  local tbl = {}
  table.insert(tbl, x)
  return tbl
end, function(x)
  table.insert(x, "hello")
  return x
end, function(x)
  return x[2]
end, string.upper)

print(val)
return pipe
