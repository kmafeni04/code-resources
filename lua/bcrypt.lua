local bcrypt = require("bcrypt")
local bcrypt_utils = {}

--- Encrypts the provided string and returns its hashed value
---@param str string
---@return string
function bcrypt_utils.encrypt(str)
	local log_rounds = 5
	local hash = bcrypt.digest(str, log_rounds)
	return hash
end

--- Verifies that a given string matches a given hash value
---@param str string
---@param hash string
---@return string?
function bcrypt_utils.verify(str, hash)
	return bcrypt.verify(str, hash)
end

return bcrypt_utils
