--- Monitor service access module
--

require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require "cjson.safe"

local req = require "shared.req"

local client = req.new()

client:open({zmq.REQ, linger = 0, connect="tcp://localhost:5511", rcvtimeo = 500}, 1)

--- Module
local _M = {}

--- Query the application status
-- @tparam table apps Application name list
-- @treturn table application status table
_M.query = function(apps)
	local req = {"query", apps}
	local reply, err = client:request(cjson.encode(req), true)

	if reply then
		reply = cjson.decode(reply)
		if reply[1] ~= 'query' then
			err = reply[2].err
			reply = nil
		else
			reply = reply[2]
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
