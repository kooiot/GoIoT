--- Data api access the datacache
--

require "shared.zhelpers"
local zmq = require 'lzmq'
local zpoller = require 'lzmq.poller'
local cjson = require "cjson.safe"
local ztimer = require 'lzmq.timer'

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

--- Read object/property value
-- @tparam strint path The path of object/property
-- @treturn table value object
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
-- @treturn table device name list
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
-- @tparam string path the device path
-- @treturn table the device tree table
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
local function new(from)
	assert(from)
	local ctx = zmq.context()
	local poller = zpoller.new(1)

	local req = require "shared.req"
	local client = req.new(ctx)

	client:open()

	local obj = {
		ctx = ctx,
		poller = poller,
		client = client,
		from = from,
	}
	
	return setmetatable(obj, {__index=class})
end

---
--@export
return {
	new = new
}
