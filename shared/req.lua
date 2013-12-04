-- Lazy Pirate client
-- Use ZMQ_RCVTIMEO to do a safe request-reply
-- To run, start lpserver and then randomly kill/restart it

require "shared.zhelpers"
local zmq = require "lzmq"

local REQUEST_TIMEOUT = 2500 -- msecs, (> 1000!)
local REQUEST_RETRIES = 3    -- Before we abandon
local SERVER_ENDPOINT = "tcp://localhost:5555"

local _M = {}

function _M.open(ctx, option, retry)
	local ctx = ctx or zmq.context()
	_M.ctx = ctx
	_M.max_retry = retry or REQUEST_RETRIES

	local SOCKET_OPTION = option or {
		zmq.REQ,
		linger   = 0;
		connect  = SERVER_ENDPOINT;
		rcvtimeo = REQUEST_TIMEOUT;
	}
	assert(SOCKET_OPTION[1] == zmq.REQ, "Incorrect socket option found in REQ")

	printf("I: connecting to server...\n")
	local client, err = ctx:socket(SOCKET_OPTION)
	zassert(client, err)
	_M.client = client
	_M.option = SOCKET_OPTION
end

-- return reply object
function _M.request(request, expect_reply)
	local reply = expect_reply and nil or true
	local err = nil

	-- 
	local retries_left = _M.max_retry

	while retries_left > 0 do
		-- We send a request, then we work to get a reply
		_M.client:send(request)

		while expect_reply do
			reply, err = _M.client:recv()

			-- Here we process a server reply and exit our loop if the
			-- reply is valid. If we didn't a reply we close the client
			-- socket and resend the request. We try a number of times
			-- before finally abandoning:

			if reply then
				printf ("I: server replied OK (%s)\n", reply)
				expect_reply = false
				retries_left = 0
				break
			elseif err:no() == zmq.EINTR then
				retries_left = 0
				break
			else
				assert(err:no() == zmq.EAGAIN)
				retries_left = retries_left - 1
				if retries_left == 0 then
					printf("E: server seems to be offline, abandoning\n")
					err = "Reach max retry count, error - "..tostring(err)
					break
				else
					printf("W: no response from server, retrying...\n")
					-- Old socket is confused; close it and open a new one
					_M.client:close()
					printf ("I: reconnecting to server...\n")
					_M.client, err = _M.ctx:socket(_M.option)
					zassert(_M.client, err)
					-- Send request again, on new socket
					_M.client:send(request)
				end
			end
		end
	end
	return reply, tostring(err)
end

return _M
