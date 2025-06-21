--[[
  Requirement: [luafilesystem](https://lunarmodules.github.io/luafilesystem)
]]

local lfs = require("lfs")
local current_time = os.time()

---@param root_dir string
---@param file_path string
---@param callback function
local function check_modification(root_dir, file_path, callback)
  local file_attrs, _, _ = lfs.attributes(file_path)
  if file_attrs then
    local mod = file_attrs.modification
    if mod > current_time then
      current_time = mod
      if file_path:match("^%./") then
        print(lfs.currentdir() .. "/" .. file_path:sub(3) .. " has been modified")
      else
        print(file_path .. " has been modified")
      end
      lfs.chdir(root_dir)
      callback()
    end
  end
end

--- For files without extensions or full file_names, an `_` can be used in front of the filename. e.g. `_lua` or `_luamon.lua`
--- Fields `exclude_file_types` and `only_file_types` can not be present at the same time
---@class Config
---@field exclude_file_types? string[] An array of file types to be ignored
---@field include_file_types? string[] An array of file types to be monitored
---@field exclude_dirs? string[] An array of directories to be ignored
---@field recursive? boolean Whether or not subdirectories should be checked, Default: `true`

---@param root_dir string
---@param dir string
---@param callback function
---@param config? Config
local function check_dir(root_dir, dir, callback, config)
  local recursive = true
  for file_path in lfs.dir(dir) do
    if file_path ~= ".." and file_path ~= "." then
      local file_attrs, _, _ = lfs.attributes(file_path)
      file_path = dir .. "/" .. file_path
      if config then
        assert(
          not (config.exclude_file_types and config.include_file_types),
          "`exclude_file_types` and `only_file_types` fields can not be present at the same time"
        )
        recursive = config.recursive and config.recursive or recursive
        if
          file_attrs
          and file_attrs.mode == "directory"
          and config.exclude_dirs
          and config.exclude_dirs[file_path:sub(#root_dir + 2)]
        then
          goto continue
        end
        if config.exclude_file_types then
          for _, file_type in ipairs(config.exclude_file_types) do
            local file_match = (
              file_path:match("^.*%." .. file_type .. "$") or file_path == dir .. "/" .. file_type:sub(2)
            )
                and true
              or false

            local ignore_bck = file_path:match(".*%.bck")

            if not file_match and not ignore_bck then
              check_modification(root_dir, file_path, callback)
              break
            end
          end
        elseif config.include_file_types then
          for _, file_type in ipairs(config.include_file_types) do
            local file_match = (
              file_path:match("^.*%." .. file_type .. "$") or file_path == dir .. "/" .. file_type:sub(2)
            )
                and true
              or false

            local ignore_bck = file_path:match(".*%.bck")

            if file_match and not ignore_bck then
              check_modification(root_dir, file_path, callback)
              break
            end
          end
        else
          check_modification(root_dir, file_path, callback)
        end
      else
        check_modification(root_dir, file_path, callback)
      end

      if recursive then
        if file_attrs and file_attrs.mode == "directory" then
          lfs.chdir(file_path)
          check_dir(root_dir, ".", callback, config)
          lfs.chdir(root_dir)
        end
      end
    end
    ::continue::
  end
end

--[[
  Monitors for file changes in a directory and calls a callback function on any file modification

  Usage:
  ```lua
  local luamon = require("luamon")
  luamon("/home/username/Desktop", function()
    print("A file has changed")
  end)

  -- If the directory is nil, it will use the current directory of the running process
  local luamon = require("luamon")
  luamon(nil, function()
    print("A file has changed")
  end)

  -- A third parameter `config` can be passed to customise how the monitoring behaves
  local config = {
    exclude_file_types = { "lua", "_luamon.lua" }
  }
  luamon(nil, function()
    print("A file has changed")
  end, config)
  ```
]]
---@param dir? string
---@param callback function
---@param config? Config
local function luamon(dir, callback, config)
  if dir then
    assert(dir:match("^/.*"), "Directory must be an absolute path but was provided: '" .. dir .. "'")
  else
    local err
    dir, err = lfs.currentdir()
    assert(dir, err)
  end
  local changed_dir, err = lfs.chdir(dir)
  assert(changed_dir, err)
  callback()

  while true do
    check_dir(dir, dir, callback, config)
  end
end

return luamon
