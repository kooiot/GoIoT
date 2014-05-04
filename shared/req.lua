--- ZeroMQ Request object

require "shared.zhelpers"
local zmq = require "lzmq"

local REQUEST_TIMEOUT = 500 -- msecs, (> 1000!)
local REQUEST_RETRIES = 3    -- Before we abandon
local SERVER_ENDPOINT = "tcp://localhost:5555"

--- Option table
-- @table Option
-- @field 0 =zmq.REQ
-- @field linger
-- @field connect connect string
-- @field rcvtimeo receive timeout in (ms)

--- request class
--@type class
local class = {}

--- Open the request connection
-- @tparam[opt] Option option default is
-- {
--		lzmq.REQ,
--		linger = 0,
--		connection = "tcp://localhost:5555",
--		rcvtimeo = 500,
-- }
-- @tparam number retry the max retry count, default is 3
-- @treturn nil
function class:open(option, retry)
	self.max_retry = retry or REQUEST_RETRIES

	local SOCKET_OPTION = option or {
		zmq.REQ,
		linger   = 0,
		connect  = SERVER_ENDPOINT,
		rcvtimeo = REQUEST_TIMEOUT,
	}
	assert(SOCKET_OPTION[1] == zmq.REQ, "Incorrect socket option found in REQ")

	--printf("I: connecting to server...\n")
	local client, err = self.ctx:socket(SOCKET_OPTION)
	zassert(client, err)
	self.client = client
	self.option = SOCKET_OPTION
end

--- Close the request connection
function class:close()
	self.client:close()
	self.client = nil
	self.option = nil
end

--- Send request and get the reply
-- @tparam string request the request string
-- @tparam boolean expect_reply whether expect for reply
-- @treturn string reply  the replied string from server
function class:request(request, expect_reply)
	local reply = expect_reply and nil or true
	local err = nil

	-- 
	local retries_left = self.max_retry

	while retries_left > 0 do
		-- We send a request, then we work to get a reply
		self.client:send(request)

		while expect_reply do
			reply, err = self.client:recv()

			-- Here we process a server reply and exit our loop if the
			-- reply is valid. If we didn't a reply we close the client
			-- socket and resend the request. We try a number of times
			-- before finally abandoning:

			if reply then
				--printf ("I: server replied OK (%s)\n", reply)
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
					self.client:close()
					printf ("I: reconnecting to server...\n")
					self.client, err = self.ctx:socket(self.option)
					zassert(self.client, err)
					-- Send request again, on new socket
					self.client:send(request)
				end
			end
		end
	end
	return reply, tostring(err)
end

--- Module functions
--@section

--- Create new request object
-- @tparam lzmq.context ctx
-- @treturn class request object
local function new(ctx)
	local ctx = ctx or zmq.context()
	return setmetatable(
	{
		ctx=ctx,
		max_retry = REQUEST_RETRIES, 
		client = nil,
		option = nil
	}, {__index = class})
end

---
-- @export
return {
	new = new
}
