
require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require 'cjson.safe'

local _M = {}

--- Calling the recv function to get message
function recv_msg()
	if not _M.sub then
		return nil, nil
	end
	-- receive the filter
	local filter = _M.sub:recv()
	if not filter then
		return nil, nil
	end

	-- receive content
	local data, err = _M.sub:recv()
	if data then
		data, err = cjson.decode(data)
		if not data then
			print( 'Cannot decode the data', err)
		end
	end
	return filter, data, err
end


function _M.open(ctx, poller)
	assert(ctx, poller)
	local sub, err = ctx:socket({
		zmq.SUB,
		subscribe = '',
		connect = 'tcp://localhost:5577',
		rcvtimeo = 1000,
	})
	zassert(sub, err)
	_M.sub = sub

	poller:add(sub, zmq.POLLIN, function()
		local filter, log, err = recv_msg()
		if filter and log then
			local api = _M.api
			if api then
				--print(log.level, log.content)
				api.on_log(filter, log)
			end
		end
	end)
end

function _M.set_api(api)
	_M.api = api
end

return _M
