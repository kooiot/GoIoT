------
-- Configuration service interface
--

require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require "cjson.safe"

local req = require "shared.comm.req"
local client = req.new()

client:open({zmq.REQ, linger = 0, connect="tcp://localhost:5522", rcvtimeo = 300}, 3)

--- Module
local _M = {}

local msg_reply = require 'shared.msg.reply'

--- Process the reply from server
local function reply(json, err)
	local reply = nil
	if json then
		reply, err = msg_reply(json)
	end
	return reply, err
end

--- Add configuration with key and value
-- @tparam string key configuration key
-- @param value value or value table
-- @treturn boolean the adding result
-- @treturn string the error message if result is false or nil
_M.add = function(key, value)
	local req = {"add", {key=key, value=value}}
	return reply(client:request(cjson.encode(req), true))
end

--- Erase configuration by key
-- @tparam string key configuration key
-- @treturn boolean the adding result
-- @treturn string the error message if result is false or nil
_M.erase = function(key)
	local req = {"erase", {key=key}}
	return reply(client:request(cjson.encode(req), true))
end

--- Set configuration with key and value
-- @tparam string key configuration key
-- @param value value or value table
-- @treturn boolean the adding result
-- @treturn string the error message if result is false or nil
_M.set = function(key, value)
	local req = {'set', {key=key, value=value}}
	return reply(client:request(cjson.encode(req), true))
end

--- Get configuration by key
-- @tparam string key configuration key
-- @return value or value table, nil for failure
-- @treturn string error message
_M.get = function(key)
	local req = {'get', {key=key}}
	local result, err = reply(client:request(cjson.encode(req), true))
	return result, err
end

--- Get all configurations
_M.list = function()
	local result, err = reply(client:request(cjson.encode({'list'}), true))
	return result, err
end

--- Clear the config database
_M.clear = function()
	local result, err = reply(client:request(cjson.encode({'clear'}), true))
	return result, err
end

--- Get the configuration service version
-- 
_M.version = function()
	local req = {'version'}
	return reply(client:request(cjson.encode(req), true))
end

return _M
