-- Data api access the datacache

require "shared.zhelpers"
local cjson = require "cjson.safe"
local ztimer = require 'lzmq.timer'
local iobussub = require 'shared.api.iobus.sub'

local class = {}

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

function class:login(user, pass, port)
	local req = {"login", {user=user, pass=pass, from=self.from, port=port}}
	return reply(self.client:request(cjson.encode(req), true))
end

-- Update value
function class:write(path, value)
	local req = {'write', {path=path, value=value, from=self.from}}
	return reply(self.client:request(cjson.encode(req), true))
end

-- Send  one command
function class:command(path, args)
	local req = {'command', {path=path, args=args, from=self.from}}
	return reply(self.client:request(cjson.encode(req), true))
end

-- Input sensor change the value
function class:publish(path, value, timestamp, quality)
	local timestamp = timestamp or ztimer.absolute_time()
	local req = {'publish', {path=path, value=value, timestamp=timestamp, quality=quality, from=self.from}}
	return reply(self.client:request(cjson.encode(req), true))
end

-- vals is the table that path, value(value, timestamp, quality)
function class:batch_publish(vals)
	local req = {'batch_publish', {pvs=vals, from=self.from}}
	return reply(self.client:request(cjson.encode(req), true))
end

function class:read(path)
	local req = {'read', {path=path, from=self.from}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

function class:enum(pattern)
	local req = {'enum', {pattern=pattern, from=self.from}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

function class:tree(path)
	local req = {'tree', {path=path, from=self.from}}
	return reply(self.client:request(cjson.encode(req), true))
end

-- subscribe to a device tree path, to get notice when data changed
function class:subscribe(devpath, cb)
	-- assert the callback, and create the subclient
	assert(cb)
	assert(self.subclient)

	local req = {'subscribe', {devpath=devpath, from=self.from}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
		-- Only bind the callbacks when subscribe successfully
		self.subclient:bind(devpath, cb)
	end
	return reply, err
end

-- unsubscribe
function class:unsubscribe(devpath)
	assert(self.subclient)
	self.subclient:unbind(devpath)
	local req = {'unsubscribe', {devpath=devpath, from=self.from}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

function class:onwrite(cb)
	assert(self.subclient)
	self.subclient.onwrite = cb
end

function class:oncommand(cb)
	assert(self.subclient)
	self.subclient.oncommand = cb
end

function class:version()
	local req = {'version', {from=self.from}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

-- Create iobus access api
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


return {
	new = new
}
