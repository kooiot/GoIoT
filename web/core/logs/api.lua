local zmq = require "lzmq"
local req = require "shared.req"
local cjson = require 'cjson.safe'
local client = req.new()

client:open({zmq.REQ, connect='tcp://localhost:5500', linger=0, rcvtimeo=500}, 1)

local typ = cgilua.QUERY.type or 'logs'
local req = {typ, {from='web', clean=true}}
local reply, err = client:request(cjson.encode(req), true)
if reply then
	local reply = cjson.decode(reply)
	if reply and #reply == 2 and reply[1] == typ and reply[2].result == true then
		put(cjson.encode(reply[2].logs))
	end
end

