--- The String Stream module
--- A library to compose strings
---@class Sstream
---@field data any[]
local sstream = {}

--- Initialize a new sstream object
---@return Sstream
function sstream.new()
  local new_sstream = {}
  for k, v in pairs(sstream) do
    new_sstream[k] = v
  end
  return new_sstream
end

--- Add a new item to the sstream object
---@param v any
function sstream:add(v)
  self.data[#self.data + 1] = tostring(v)
end

--- Add new items to the sstream object
---@param ... any
function sstream:add_many(...)
  local args = { ... }
  for _, v in ipairs(args) do
    self.data[#self.data + 1] = tostring(v)
  end
end

--- Add a list of items to the sstream object connected by a provided seperator or `", "`
---@param list any[]
---@param sep string?
function sstream:add_list(list, sep)
  sep = sep or ", "
  for i, v in ipairs(list) do
    list[i] = tostring(v)
    self.data[#self.data + 1] = list[i]
    if i ~= #list then
      self.data[#self.data + 1] = sep
    end
  end
end

--- Converts the current sstream object to a string and clear it's data
--- If there is no data in the object, this returns `nil`
---@nodiscard
---@return string?
function sstream:to_string()
  if not next(self.data) then
    return nil
  end
  local s = table.concat(self.data)
  for i, _ in pairs(self.data) do
    self.data[i] = nil
  end
  return s
end

return sstream
