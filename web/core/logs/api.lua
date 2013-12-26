local zmq = require "lzmq"
local req = require "shared.req"
local cjson = require 'cjson.safe'
local client = req.new()

client:open({zmq.REQ, connect='tcp://localhost:5500', linger=0, rcvtimeo=500}, 1)

local req = {'logs', {from='web'}}
local reply, err = client:request(cjson.encode(req), true)
if reply then
	put(reply)
end

