-- Data api access the datacache

require "shared.zhelpers"
local zmq = require "lzmq"
local zpoller = require 'lzmq.poller'
local cjson = require "cjson.safe"
local ztimer = require 'lzmq.timer'

local _M = {}

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

function class:login(user, pass)
	local req = {"login", {user=user, pass=pass, from=self.from}}
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
	local req = {'set', {path=path, value=value, timestamp=timestamp, quality=quality, from=self.from}}
	return reply(self.client:request(cjson.encode(req), true))
end

-- vals is the table that path, value(value, timestamp, quality)
function class:batch_publish(vals)
	local req = {'sets', {pvs=vals, from=self.from}}
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

function class:subscribe(path, cb)
	-- assert the callback, and create the subclient
	assert(cb)
	if not self.subclient then
		local sub = require 'shared.api.iobus.sub'
		self.subclient, err = sub.new(self.from, self.ctx, self.poller)
		assert(self.subsclient, err)
	end

	local req = {'subscribe', {path=path, from=self.from}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
		-- Only bind the callbacks when subscribe successfully
		self.subclient:bind(path, cb)
	end
	return reply, err
end

function class:unsubscribe(path)
	if not self.subclient then
		return true
	end
	self.subclient:unbind(path)
	local req = {'unsubscribe', {path=path, from=self.from}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

function class:version()
	local req = {'version', {from=self.from}}
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

function class:set_subscribe_cb(cb)
end

-- Create iobus access api
local function new(from, ctx, poller)
	assert(from)
	local ctx = ctx or zmq.context()
	local poller = poller or zpoller.new(1)

	local req = require "shared.req"
	local client = req.new(ctx)

	client:open()

	local obj = {
		ctx = ctx,
		poller = poller,
		client = client,
		from = from
	}
	
	return setmetatable(obj, {__index=class})
end


return {
	new = new
}
