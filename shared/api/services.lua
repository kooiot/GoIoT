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

local function get_reply(reply, key)
	local reply, err = cjson.decode(reply)
	if #reply ~= 2 or (key and reply[1] ~= key) then
		err = 'Error result json '..cjson.encode(reply)..' - '..(key or '')
		reply = nil
	else
		reply = reply[2]
	end
	return reply, err
end

--- Abort the services 
-- @tparam string name services name
-- @treturn boolean result
-- @treturn string error
-- @treturn table services status table {
--	status = 'xxxx' -- 'DONE' 'ERROR' 'RUNNING'
--	err = 'xxxx
--	}
_M.abort = function(name)
	local req = {"abort", {name=name}}
	local reply, err = client:request(cjson.encode(req), true)
	print(reply)

	if reply then
		reply, err = get_reply(reply, 'abort')

		if reply then
			err = reply and reply.err or err
			return reply.result, err, reply.status
		end
	end
	return nil, err
end

--- Query the services running status
-- @tparam string name services name
-- @treturn table services status table {
--	status = 'xxxx' -- 'DONE' 'ERROR' 'RUNNING'
--	err = 'xxxx
--	}
_M.query = function(name)
	local req = {"query", {name=name}}
	local reply, err = client:request(cjson.encode(req), true)

	if reply then
		reply, err = get_reply(reply, 'query')
		if reply and reply.result then
			reply = reply.status
		else
			err = reply and reply.err or err
			reply = nil
		end
	end
	return reply, err
end

--- Add one services
-- @tparam string name services name
-- @tparam string dostr services code
-- @tparam boolean keepalive keep this services running always, restart it when it quited (not implemented)
-- @treturn boolean result
-- @treturn string error
_M.add = function(name, dostr, keepalive)
	local req = {'add', {name=name, dostr=dostr, keepalive=keepalive}}
	local reply, err = client:request(cjson.encode(req), true)
	print(reply)
	if reply then
		reply, err = get_reply(reply, 'add')
		if reply then
			err = reply.err
			reply = reply.result
		end
	end
	return reply, err
end

--- List all services' status
-- @treturn table services status tables
_M.list = function(name, dostr)
	local req = {'list', {name=name, dostr=dostr}}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply, err = get_reply(reply, 'list')
		if reply and reply.result then
			reply = reply.status
		else
			err = reply and reply.err or err
			reply = nil
		end
	end
	return reply, err
end

--- Get the monitor service version
-- 
_M.version = function()
	local req = {'version'}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

return _M
