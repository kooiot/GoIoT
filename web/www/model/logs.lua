local zmq = require "lzmq"
local req = require "shared.req"
local cjson = require 'cjson.safe'

local _M = {}

function _M.new()
	if not _M.client then
		_M.client = req.new()
		_M.client:open({zmq.REQ, connect='tcp://localhost:5500', linger=0, rcvtimeo=500}, 1)
	end
	return _M
end

function _M:query(typ)
	local req = {typ, {from='web', clean=true}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		local reply = cjson.decode(reply)
		if reply and #reply == 2 and reply[1] == typ and reply[2].result == true then
			return cjson.encode(reply[2].logs)
		else
			return nil, reply[2].err
		end
	else
		return nil, err
	end
end

return _M
