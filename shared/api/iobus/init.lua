--- Data api access the datacache
--

require "shared.zhelpers"
local cjson = require "cjson.safe"
local ztimer = require 'lzmq.timer'
local iobussub = require 'shared.api.iobus.sub'

--- metatable class 
-- @type class
local class = {}

--- Process reply message
local function reply(json, err)
	local reply = nil
	if json then
		reply, err = cjson.decode(json)
		if reply then
			if #reply == 2 then
				err = reply[2].err
				reply = reply[2].result
			else
				err = "incorrect reply json"
			end
		end
	end
	return reply, err
end

--- Send login to iobus:
-- @tparam string user username
-- @tparam string pass password
-- @tparam number port application service port, nil or 0 won't accept device tree querying
-- @return ok
-- @treturn string error message
function class:login(user, pass, port)
	local req = {"login", {user=user, pass=pass, from=self.from, port=port}}
	return reply(self.client:request(cjson.encode(req), true))
end

--- Update/Write value by path
-- @tparam string path The object/prop path
-- @param value Value
-- @return ok
-- @treturn string error message
function class:write(path, value)
	local req = {'write', {path=path, value=value, from=self.from}}
	return reply(self.client:request(cjson.encode(req), true))
end

--- Send one command
-- @tparam strint path The path of command object
-- @tparam table args The command arguments
-- @return ok
-- @treturn string error message
function class:command(path, args)
	local req = {'command', {path=path, args=args, from=self.from}}
	return reply(self.client:request(cjson.encode(req), true))
end

--- Publish the values changes
-- @tparam string path Object/Property path
-- @param  value Object value
-- @tparam number timestamp Timestamp
-- @tparam number quality Quality
function class:publish(path, value, timestamp, quality)
	local timestamp = timestamp or ztimer.absolute_time()
	local req = {'publish', {path=path, value=value, timestamp=timestamp, quality=quality, from=self.from}}
	return reply(self.client:request(cjson.encode(req), true))
end

--- Publish value changes for few object/property
-- @tparam table vals The table contains path, value(value, timestamp, quality)
function class:batch_publish(vals)
	local req = {'batch_publish', {pvs=vals, from=self.from}}
	return reply(self.client:request(cjson.encode(req), true))
end

--- Read object/property value
-- @tparam strint path The path of object/property
-- @treturn table value object { value, timestamp, quality }
-- @treturn string error message
function class:read(path)
	local req = {'read', {path=path, from=self.from}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

--- Enum devices according to pattern
-- @tparam string pattern( refer to string.match pattern  )
-- @treturn table device name list { 'namespace' = { 'device1', 'device2' } 'namespace2' = { 'device2', 'devices' }}

function class:enum(pattern)
	local req = {'enum', {pattern=pattern, from=self.from}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2].devices
		--[[
			devices = {
				'namespace' = { 'device1', 'device2' }，
				'namespace2' = { 'device2', 'devices' },
			}
		]]--
	end
	return reply, err
end

--- Read the device tree meta from iobus
-- @tparam string path the device path (including namespace and device name)
-- @treturn table the device tree table  { verinfo = {}, device {inputs={}, comands={} } }
function class:tree(path)
	local req = {'tree', {path=path, from=self.from}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		reply, err = cjson.decode(reply)
		if type(reply) == 'table' then
			reply = reply[2].tree
		end
	end
	return reply, err
end

--- Subscribe to a path, to get notice when data changed
-- @tparam string pattern The match pattern (refer to string.match)
-- @tparam function cb Callback function when changes happen
-- @return ok
-- @treturn string error message
function class:subscribe(pattern, cb)
	-- assert the callback, and create the subclient
	assert(cb)
	assert(self.subclient)

	local req = {'subscribe', {pattern=pattern, from=self.from}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
		-- Only bind the callbacks when subscribe successfully
		self.subclient:bind(pattern, cb)
	end
	return reply, err
end

--- Unsubscribe cov
-- @tparam string pattern The match pattern (refer to string.match)
-- @return ok
-- @treturn string error message
function class:unsubscribe(pattern)
	assert(self.subclient)
	self.subclient:unbind(pattern)
	local req = {'unsubscribe', {pattern=pattern, from=self.from}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

--- Register the callback function for data writing
-- @tparam function cb Callback function
function class:onwrite(cb)
	assert(self.subclient)
	self.subclient.onwrite = cb
end

--- Register the callback function for command handing
-- @tparam function cb Callback function
function class:oncommand(cb)
	assert(self.subclient)
	self.subclient.oncommand = cb
end

--- Register the udpate event callback handler
-- @tparam function cb Callback function
function class:onupdate(cb)
	assert(self.subclient)
	self.subclient.onupdate = cb
end

--- Get the IOBUS service version
-- 
function class:version()
	local req = {'version', {from=self.from}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

--- Module functions
-- @section


--- Create iobus access api
-- @tparam string from Your application namespace
-- @tparam lzmq.context ctx
-- @tparam lzmq.poller poller
-- @treturn class the api object
local function new(from, ctx, poller)
	assert(from and ctx and poller)

	local req = require "shared.req"
	local client = req.new(ctx)

	client:open()

	local subclient, err = iobussub(from, ctx, poller)
	assert(subclient, err)

	local obj = {
		ctx = ctx,
		poller = poller,
		client = client,
		subclient = subclient,
		from = from,
	}
	
	return setmetatable(obj, {__index=class})
end

---
--@export
return {
	new = new
}
