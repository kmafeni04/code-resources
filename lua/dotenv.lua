-- Original work: veeponym, https://gist.github.com/veeponym/6a8f7ba661032ddce1e941095a998a69

--[[
  Implements the ability to use `.env` files while also being a drop in replacement for `os.getenv`

  Usage:
  ```lua
  local dotenv = require("dotenv")
  local env, err = dotenv:load()
  -- Handle the err as you see fit
  local var = env:get("YOUR_VAR")
  ```
]]
---@class Dotenv
local dotenv = {}

--- Reads a file
--- Returns its contents as a string or `nil` with an error
---@param filename string
---@return string? content
---@return string? err
local function read_file(filename)
  local file = io.open(filename, "r")
  if not file then
    return nil, "File not found: " .. filename
  end
  local content = file:read("*a")
  file:close()
  return content
end

--- Parses the `.env` file's content
--- Returns a table of key-value pairs
---@param content string
---@return table<string,string> vars
local function parse_env(content)
  local items = {}
  ---@type string
  for line in content:gmatch("[^\r\n]+") do
    -- Trim any leading or trailing whitespace from the line
    line = line:match("^%s*(.-)%s*$")
    -- Ignore empty lines or lines starting with #
    if line ~= "" and line:sub(1, 1) ~= "#" then
      -- Split the line by the first = sign
      local key, value = line:match("([^=]+)=(.*)")
      -- Trim any leading or trailing whitespace from the key and value
      key = key:match("^%s*(.-)%s*$")
      value = value:match("^%s*(.-)%s*$")
      -- Check if the value is surrounded by double quotes
      if value:sub(1, 1) == '"' and value:sub(-1, -1) == '"' then
        -- Remove the quotes and unescape any escaped characters
        value = value:sub(2, -2):gsub('\\"', '"')
      end
      -- Check if the value is surrounded by single quotes
      if value:sub(1, 1) == "'" and value:sub(-1, -1) == "'" then
        -- Remove the quotes
        value = value:sub(2, -2)
      end
      -- Store the key-value pair in the table
      items[key] = value
    end
  end
  return items
end

--[[
  Table containing all your env variables
]]
---@class Dotenv.Env
dotenv.env = {}

--[[
  Gets the environment variable from the .env file or directly from the os
  Returns the value of that variable or nil
]]
---@param env string
---@param default? string default value if no env is found
---@return string? env
function dotenv.env:get(env, default)
  self[env] = self[env] or os.getenv(env) or default
  return self[env]
end

--[[
  Loads the specified file or a `.env` file
  Returns the env table or the env table with an error
]]
---@param filename? string
---@return Dotenv.Env env
---@return string? err
function dotenv:load(filename)
  filename = filename or ".env"
  local content, err = read_file(filename)
  if not content then
    return self.env, err
  end
  local items = parse_env(content)
  for key, value in pairs(items) do
    if not self.env[key] then
      self.env[key] = value
    end
  end
  return self.env
end

return dotenv
