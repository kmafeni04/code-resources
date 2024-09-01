local mod
local vars = {}

--[[
  Implements "import"
  Only works when a module is a lua table

  E.g:
  ```lua
  -- module.lua

  local module = {}
  module.hi = "hello"
  return module
  ```
  
  Usage:
  ```lua
  -- main.lua

  local import = require("import")
  import.from("module")
  import.import("hi")
  import.as("h")

  print(import.h)
  --> Prints "hello"
  ```
  Note: This is not a serious body of work, I made this simply for experimentation's sake and you are probably better off just using the regular `require()` syntax
]]
---@class Imp
---@field [string] any
local import = {}

--[[
  Declares the file you are importing from

  Usage:
  ```lua
  import.from("module")
  ```
]]
---@param module string
import.from = function(module)
  mod = require(module)
end

--[[
  What you wish to import from the module

  Usage:
  ```lua
  import.import("module_field")
  import.import({ "module_field1", "module_filed2" })
  ```
]]
---@param entities string[] | string
import.import = function(entities)
  if type(entities) == "string" then
    vars[1] = mod[entities]
    import[entities] = vars[1]
  end
  if type(entities) == "table" then
    for index, entity in pairs(entities) do
      vars[index] = mod[entity]
      import[entity] = vars[index]
    end
  end
end
--[[
  Alias your imports

  Usage:
  ```lua
  import.as("new_name")
  import.as({ "new_name1", "new_name2" })
  ```
]]
---@param names string[] | string
import.as = function(names)
  if type(names) == "string" then
    import[names] = vars[1]
  end
  if type(names) == "table" then
    for index, name in pairs(names) do
      import[name] = vars[index]
    end
  end
end

return import
