-- Lazy Pirate client
-- Use ZMQ_RCVTIMEO to do a safe request-reply
-- To run, start lpserver and then randomly kill/restart it

require "zhelpers"
local zmq = require "lzmq"
local cjson = require "cjson.safe"

local REQUEST_TIMEOUT = 2500 -- msecs, (> 1000!)
local REQUEST_RETRIES = 3    -- Before we abandon
local SERVER_ENDPOINT = "tcp://localhost:5555"

local ctx = zmq.context()

local SOCKET_OPTION = {zmq.REQ,
  linger   = 0;
  connect  = SERVER_ENDPOINT;
  rcvtimeo = REQUEST_TIMEOUT;
}

printf("I: connecting to server...\n")
local client, err = ctx:socket(SOCKET_OPTION)
zassert(client, err)

-- return reply object
local function request(req, expect_reply)
	local reply = expect_reply and nil or true
	local err = nil

	-- 
	local retries_left = REQUEST_RETRIES
	local request = cjson.encode(req)

	while retries_left > 0 do
		-- We send a request, then we work to get a reply
		client:send(request)

		while expect_reply do
			reply, err = client:recv()

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
					client:close()
					printf ("I: reconnecting to server...\n")
					client, err = ctx:socket(SOCKET_OPTION)
					zassert(client, err)
					-- Send request again, on new socket
					client:send(request)
				end
			end
		end
	end
	return reply, tostring(err)
end

local _M = {}

_M.add = function(name, desc, value)
	local req = {"add", {name=name, desc=desc, value=value}}
	return request(req, true)
end

_M.erase = function(name)
	local req = {"erase", {name=name}}
	return request(req, true)
end

_M.set = function(name, val, timestamp)
	local req = {'set', {name=name, value=val, timestamp=timestamp}}
	return request(req, true)
end

_M.get = function(name)
	local req = {'get', {name=name}}
	reply, err = request(req, true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

return _M
