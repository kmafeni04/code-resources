#!/bin/lua5.1

-- Generates a new file/files in a lapis project from a gen-type

-- REQUIREMNTS:
-- lua5.1, luarocks
--
-- Save this script in your $PATH as lapis-gen and give the file execute permissions (chmod +x lapis-gen)
--
-- Usage: lapis-gen [-h] <command>
--
-- Options:
--     -h, --help           Show this help message
-- Commands:
--     view                 Generates a new view file
--     controller           Generates a new controller file
--     action               Generates a new action in a specified controller
--     make_migration       Generates migration files
--     scaffold             Generates multiple files to bootstap functionality

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
    local func
    if _VERSION == "Lua 5.1" then
      func, _ = loadstring("return " .. expr)
      if func then
        setfenv(func, variables)
      end
    else
      func, _ = load("return " .. expr, nil, nil, variables)
    end
    if func then
      local success, result = pcall(func)
      if success and result then
        return tostring(result)
      end
    else
      return "{{" .. expr .. "}}"
    end
  end

  local new_str = str:gsub("{{(.-)}}", function(expr)
    return eval(expr:match("^%s*(.-)%s*$"))
  end)

  return new_str
end

local function print_help()
  print([[
Usage: lapis-gen [-h] <command>

Generates a new file/files in a lapis project from a gen-type

Options:
    -h, --help           Show this help message
  
Commands:
    view                 Generates a new view file
    controller           Generates a new controller file
    action               Generates a new action in a specified controller
    make_migration       Generates migration files
    scaffold             Generates multiple files to bootstap functionality]])
end

local arguments = {
  ["-h"] = true,
  ["--help"] = true,
  ["view"] = true,
  ["controller"] = true,
  ["action"] = true,
  ["make_migration"] = true,
  ["scaffold"] = true,
}

if not arg[1] or arg[1] == "-h" or arg[1] == "--help" then
  print_help()
  return
end

if not arguments[arg[1]] then
  local arg_1 = arg[1]
  print(interp("'{{arg_1}}' is not a vaild argument\n"))
  print_help()
  return
end

local haslfs, lfs = pcall(require, "lfs")
if not haslfs then
  os.execute("luarocks install luafilesystem --lua-version=5.1")
  lfs = require("lfs")
end

---@param name string
local function print_provide(name)
  print(interp("Please provide a name for this {{name}}"))
end

---@param name string
local function gen_view_lua(name)
  name = name:gsub(".lua", "")
  local lua_content = interp([[
local Widget = require("lapis.html").Widget

return Widget:extend(function(self)
  h1("This is the {{name}} widget")
end)
]])

  if lfs.attributes(name .. ".lua", "mode") == "file" then
    print("That file already exists")
    print("Would you like to override it? [Y/N]")
    ---@type string
    local choice = io.read():lower()
    if choice == "y" then
      os.execute(interp("rm  {{name}}.lua"))
    elseif choice == "n" then
      print("Operation terminated")
      return
    else
      print("Invalid input")
      os.exit(1)
    end
  end

  local lua_file = io.open(interp("{{name}}.lua"), "w")
  assert(lua_file):write(lua_content)
  assert(lua_file):close()
  local currentdir = lfs.currentdir()
  print(interp("File: '{{name}}.lua' was created in the {{currentdir}} directory"))
end

---@param name string
local function gen_view_etlua(name)
  name = name:gsub(".etlua", "")
  local etlua_content = interp([[
<h1> This is the {{name}} etlua view </h1>
]])

  if lfs.attributes(name .. ".etlua", "mode") == "file" then
    print("That file already exists")
    print("Would you like to override it? [Y/N]")
    ---@type string
    local choice = io.read():lower()
    if choice == "y" then
      os.execute(interp("rm {{name}}.etlua"))
    elseif choice == "n" then
      print("Operation terminated")
      return
    else
      print("Invalid input")
      os.exit(1)
    end
  end

  local etlua_file = io.open(interp("{{name}}.etlua"), "w")
  assert(etlua_file):write(etlua_content)
  assert(etlua_file):close()
  local currentdir = lfs.currentdir()
  print(interp("File: '{{name}}.etlua' was created in the {{currentdir}} directory"))
end

---@param view_type string
---@param view_name string
local function gen_view(view_type, view_name)
  if lfs.attributes("views", "mode") == "directory" then
  else
    os.execute("mkdir views")
  end
  lfs.chdir("views")
  if view_type == "lua" then
    gen_view_lua(view_name)
  end

  if view_type == "etlua" then
    gen_view_etlua(view_name)
  end
  lfs.chdir("..")
end

local nginx_found = false
if lfs.attributes("nginx.conf", "mode") == "file" then
  nginx_found = true
end

if arg[1] == "view" then
  local view_arguments = {
    ["-h"] = true,
    ["--help"] = true,
    ["lua"] = true,
    ["etlua"] = true,
  }
  local function print_view_help()
    print([[
Usage: lapis-gen view [-h] [view_type] [name]

Generates a new view file in the views directory

Arguments:
    view_type            The type of view file you want to create(lua, etlua)
    name                 The name of the view file

Options:
    -h, --help           Shows this help message]])
  end
  for i in ipairs(arg) do
    if not arg[2] or arg[i] == "-h" or arg[i] == "--help" then
      print_view_help()
      return
    end
  end
  if not view_arguments[arg[2]] then
    local arg_2 = arg[2]
    print(interp("'{{arg_2}}' is not a valid view type \n"))
    print_view_help()
    return
  end
  if not arg[3] then
    print_provide("view\n")
    print_view_help()
    os.exit(1)
  end

  if nginx_found then
    gen_view(arg[2], arg[3])
    return
  end
end

---@param controller  string
---@param name  string
local function gen_action(controller, name)
  if not name then
    print_provide("action")
    os.exit(1)
  end
  lfs.chdir("controllers")
  if lfs.attributes(interp("{{controller}}_controller.lua"), "mode") == "file" then
  else
    print("That controller does not exist")
    print(interp([[
To create that controller, please run:
lapis-gen controller {{controller}}]]))
    os.exit(1)
  end
  controller = interp("{{controller}}_controller")
  local action_content = interp([[
function {{controller}}:{{name}}()
  return "hello from {{name}} in the {{controller}} controller"
end
]])
  local controller_file = io.open(interp("{{controller}}.lua"), "r")
  local lines = {}
  for line in assert(controller_file):lines() do
    table.insert(lines, line .. "\n")
  end
  assert(controller_file):close()
  table.insert(lines, #lines - 1, interp("\n{{action_content}}"))
  controller_file = io.open(interp("{{controller}}.tmp.lua"), "w")
  for _, line in ipairs(lines) do
    assert(controller_file):write(line)
  end
  assert(controller_file):close()
  os.remove(interp("{{controller}}.lua"))
  os.rename(interp("{{controller}}.tmp.lua"), interp("{{controller}}.lua"))
  print(interp("Action: '{{name}}' created in the {{controller}}"))
  lfs.chdir("..")
end

if arg[1] == "action" then
  local function print_action_help()
    print([[
Usage: lapis-gen action [-h] [controller] [name]

Generates a new controller file in the controllers directory

Arguments:
    controller           The name of the controller you're adding the action to
    name                 The name of the action

Options:
    -h, --help           Shows this help message]])
  end
  for i in ipairs(arg) do
    if not arg[2] or arg[i] == "-h" or arg[i] == "--help" then
      print_action_help()
      return
    end
  end
  if nginx_found then
    gen_action(arg[2], arg[3])
    return
  end
end

---@param name string
local function gen_controller(name)
  if not name then
    print_provide("controller")
    os.exit(1)
  end
  if lfs.attributes("controllers", "mode") == "directory" then
  else
    os.execute("mkdir controllers")
  end
  lfs.chdir("controllers")
  name = name:lower():gsub("_controller", "")
  name = name:lower():gsub("controller", "")
  if lfs.attributes(interp("{{name}}_controller.lua"), "mode") == "file" then
    print("This file already exists")
    print("Would you like to override it? [Y/N]")
    ---@type string
    local choice = io.read():lower()
    if choice == "y" then
      os.execute(interp("rm -rf {{name}}"))
    elseif choice == "n" then
      print("Operation terminated")
      return
    end
  end
  local controller_name = name .. "_controller"
  local controller_content = interp([[
local {{controller_name}} = {}

return {{controller_name}}
]])
  local controller_file = io.open(name .. "_controller.lua", "w")
  assert(controller_file):write(controller_content)
  assert(controller_file):close()
  local currentdir = lfs.currentdir()
  print(interp("File: '{{controller_name}}' was created in the {{currentdir}} directory"))
  gen_action(name, "index")
end

if arg[1] == "controller" then
  local function print_controller_help()
    print([[
Usage: lapis-gen controller [-h] [name]

Generates a new controller file in the controllers directory

Arguments:
    name                 The name of the controller

Options:
    -h, --help           Shows this help message]])
  end
  for i in ipairs(arg) do
    if not arg[2] or arg[i] == "-h" or arg[i] == "--help" then
      print_controller_help()
      return
    end
  end

  if nginx_found then
    gen_controller(arg[2])
    return
  end
end

---@param name string
local function gen_make_migration(name)
  name = name:lower()
  if lfs.attributes("migrations", "mode") == "directory" then
  else
    os.execute("mkdir migrations")
  end
  lfs.chdir("migrations")
  ---@param file string
  for file in lfs.dir(".") do
    if file:match(name) then
      print("A migration file matching your provided name already exists")
      os.exit(1)
    end
  end
  local time = os.time()
  local migration_content = interp([[
local db = require("lapis.db")
local schema = require("lapis.db.schema")
local types = schema.types

return function()
  schema.create_table("{{name}}", {
    { "id", types.integer },

    "PRIMARY KEY (id)",
  })
end]])
  local migration_filename = interp("{{time}}_create_{{name}}")
  local migration_file = io.open(interp("{{migration_filename}}.lua"), "w")
  assert(migration_file):write(migration_content)
  assert(migration_file):close()
  local currentdir = lfs.currentdir()
  print(interp("File: '{{migration_filename}}.lua' was created in the {{currentdir}} directory"))
  lfs.chdir("..")
  if lfs.attributes("migrations.lua", "mode") == "file" then
  else
    local migrations_content = [[
local db = require("lapis.db")
local schema = require("lapis.db.schema")
local types = schema.types

return {
  
}
]]
    local migrations_file = io.open("migrations.lua", "w")
    assert(migrations_file):write(migrations_content)
    assert(migrations_file):close()
    print("File written: migrations.lua")
  end
  local migrations_file = io.open("migrations.lua", "r")
  local lines = {}
  for line in assert(migrations_file):lines() do
    table.insert(lines, interp("{{line}}\n"))
  end
  assert(migrations_file):close()
  table.insert(
    lines,
    #lines,
    interp([[
  [{{time}}] = function()
    local create_{{name}} = require("migrations.{{filename}}")
    create_{{name}}()
  end,
]])
  )
  local temp_migrations_file = io.open("migrations.tmp.lua", "w")
  for _, line in ipairs(lines) do
    assert(temp_migrations_file):write(line)
  end
  assert(temp_migrations_file):close()
  os.remove("migrations.lua")
  os.rename("migrations.tmp.lua", "migrations.lua")
end

if arg[1] == "make_migration" then
  local function print_make_migration_help()
    print([[
Usage: lapis-gen make_migration [-h] [name]

Generates a new migration file in the migrations directory

Arguments:
    name                 The name of the action

Options:
    -h, --help           Shows this help message]])
  end
  for i in ipairs(arg) do
    if not arg[2] or arg[i] == "-h" or arg[i] == "--help" then
      print_make_migration_help()
      return
    end
  end

  if nginx_found then
    gen_make_migration(arg[2])
  end
end

--TODO Handle migration

---@param view_type string
---@param name string
local function gen_scaffold(view_type, name)
  name = name:lower()

  lfs.chdir("views")

  if lfs.attributes(name, "mode") == "directory" then
  else
    os.execute(interp("mkdir {{name}}"))
  end

  lfs.chdir(name)

  if view_type == "etlua" then
    gen_view_etlua("index")
    gen_view_etlua("edit")
    gen_view_etlua("show")
    gen_view_etlua("new")
  end
  if view_type == "lua" then
    gen_view_lua("index")
    gen_view_lua("edit")
    gen_view_lua("show")
    gen_view_lua("new")
  end

  lfs.chdir("..")
  lfs.chdir("..")

  gen_controller(name)
  gen_action(name, "edit")
  gen_action(name, "show")
  gen_action(name, "new")

  os.execute(interp("lapis generate model {{name}}"))
  gen_make_migration(name)
end

--TODO Finish scaffold generator
if arg[1] == "scaffold" then
  local function print_scaffold_help()
    print([[
Usage: lapis-gen scaffold [-h] [view_type] [name]
 
Generates a new scaffold

Arguments:
    name                 The name of the scaffold
    view_type            The type of view file you want to create(lua, etlua)

Options:
    -h, --help           Shows this help message]])
  end
  for i in ipairs(arg) do
    if not arg[2] or arg[i] == "-h" or arg[i] == "--help" then
      print_scaffold_help()
      return
    end
  end
  if not arg[2] then
    print("Please specify a view type\n")
    print_scaffold_help()
    os.exit(1)
  end
  if not arg[3] then
    print_provide("scaffold\n")
    print_scaffold_help()
    os.exit(1)
  end
  local view_arguments = {
    ["lua"] = true,
    ["etlua"] = true,
  }

  if not view_arguments[arg[2]] then
    local arg_2 = arg[2]
    print(interp("'{{arg_2}}' is not a valid view type \n"))
    print_scaffold_help()
    os.exit(1)
  end

  if nginx_found then
    gen_scaffold(arg[2], arg[3])
    return
  end
end
if not nginx_found then
  print("File: 'nginx.conf' not found")
  os.exit(1)
end
