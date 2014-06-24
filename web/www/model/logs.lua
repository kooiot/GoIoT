local zmq = require "lzmq"
local req = require "shared.req"
local cjson = require 'cjson.safe'

local msg_reply = require 'shared.msg.reply'

local _M = {}

function _M.new(m, ctx)
	if not _M.client then
		_M.client = req.new(ctx)
		_M.client:open({zmq.REQ, connect='tcp://localhost:5500', linger=0, rcvtimeo=500}, 1)
	end
	return _M
end

function _M:query(typ, clean)
	assert(typ)
	assert(typ=='logs' or typ=='packets')
	local req = {typ, {from='web', clean=clean}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		return msg_reply(reply)
	else
		return nil, err
	end
end

function _M:close()
	self.client:close()
	self.client = nil
end

return _M
