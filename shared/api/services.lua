--- API for accessing services runner
-- Which could help you to start an process to get heavy blocked work done
--

require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require "cjson.safe"

local req = require "shared.req"

local client = req.new()

client:open({zmq.REQ, linger = 0, connect="tcp://localhost:5115", rcvtimeo = 300}, 2)

--- Module
local _M = {}

local msg_reply = require 'shared.msg.reply'

local function get_reply(reply, err)
	if reply then
		return msg_reply(reply)
	end
	return reply, err
end

--- Abort the services 
-- @tparam string name services name
-- @treturn boolean result
-- @treturn string error
_M.abort = function(name)
	local req = {"abort", {name=name}}
	return get_reply(client:request(cjson.encode(req), true))
end

--- Query the services running status
-- @tparam string name services name
-- @treturn table services status table {
--	status = 'xxxx' -- 'DONE' 'ERROR' 'RUNNING'
--	percent = 10
--	logs = {'', ''}
--	}
_M.query = function(name)
	local req = {"query", {name=name}}
	return get_reply(client:request(cjson.encode(req), true))
end

--- Add one services
-- @tparam string name services name
-- @tparam string dostr services code
-- @tparam string desc services description
-- @tparam boolean keepalive keep this services running always, restart it when it quited (not implemented)
-- @treturn boolean result
-- @treturn string error
_M.add = function(name, dostr, desc, keepalive)
	local req = {'add', {name=name, dostr=dostr, desc=desc, keepalive=keepalive}}
	return get_reply(client:request(cjson.encode(req), true))
end

--- Set the result(error output)
-- @tparam string name services name
-- @tparam boolean result result boolean
-- @tparam string output output text
-- @treturn boolean result
-- @treturn string error
_M.result = function(name, result, output)
	local req = {'result', {name=name, result=result, output=output}}
	return get_reply(client:request(cjson.encode(req), true))
end

--- Set progress for service
-- @tparam string name services name
-- @tparam string desc progress description
-- @tparam number prec progress percent (nil for logging the desc only)
-- @treturn boolean result
-- @treturn string error
_M.progress = function(name, desc, prec)
	local req = {'progress', {name=name, desc=desc, prec=prec}}
	return get_reply(client:request(cjson.encode(req), true))
end

--- List all services' status
-- @treturn table services status table(array)
_M.list = function(name, dostr)
	local req = {'list', {name=name, dostr=dostr}}
	return get_reply(client:request(cjson.encode(req), true))
end

--- Get the monitor service version
-- 
_M.version = function()
	local req = {'version'}
	return get_reply(client:request(cjson.encode(req), true))
end

return _M
