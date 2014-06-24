--- Monitor service access module
--

require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require "cjson.safe"

local req = require "shared.req"
local msg_reply = require 'shared.msg.reply'

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
	--print(reply, err)

	if reply then
		return msg_reply(reply)
	else
		return reply, err
	end
end

--- Get the monitor service version
-- 
_M.version = function()
	local req = {'version'}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		return msg_reply(reply)
	else
		return reply, err
	end
end

return _M
