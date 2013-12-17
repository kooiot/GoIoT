
require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require "cjson.safe"

local req = require "shared.req"

local client = req.new()

client:open({zmq.REQ, linger = 0, connect="tcp://localhost:5511", rcvtimeo = 500}, 1)

local _M = {}

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

_M.version = function()
	local req = {'version'}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end


return _M
