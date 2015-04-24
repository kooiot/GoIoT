
--- Helper function for parsing the reply message

local cjson = require 'cjson.safe'

--- Decode the raw data to message object
-- @function Module
-- @tparam string raw the raw data
-- @tparam string msg the message id to verify the raw data to make sure they have same id
-- @treturn table message object
-- @treturn string error message
return function(raw, msg)
	-- Try to decode as json
	local obj, err = cjson.decode(raw)
	if not obj then
		return nil, err
	end

	-- Check the json object type and we require the [1] as message key
	if type(obj) ~= 'table' or not obj[1] then
		return nil, 'Message format incorrect, it has to be an table(array) in json', obj
	end

	-- If the message is error message
	if obj[1] == 'error' then
		return nil, obj[3] or 'Error message returns', obj
	end

	-- Check the msg if present
	if msg and msg ~= obj[1] then
		return nil, 'Error message type returned from server', obj
	end

	--[[
	if not obj[2] then
		assert(obj[3])
	end
	]]--
	if obj[2] == cjson.null then
		return nil, obj[3]
	end

	return obj[2], obj[3]
end

