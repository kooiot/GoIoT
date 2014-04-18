
require 'shared.zhelpers'
local zmq = require 'lzmq'
local log = require 'shared.log'
local cjson = require 'cjson.safe'

local ptable = {}

local publisher = nil

local function init(ctx)
	local pub, err = ctx:socket{zmq.PUB, bind = "tcp://*:5566"}
	zassert(pub, err)
	publisher = pub
	return publisher
end

local function getsub(path)
	for k, v in pairs(ptable) do
	end
end

local function cov(path, value)
	for pattern, v in pairs(ptable) do
		local from = path:match('^([^/]+)/.+')
		-- publish changes
		if path:match(pattern) then
			for k, v in pairs(v) do
				if k ~= from then
					--log:debug('IOBUS', 'Publish data changes for '..path..':'..k)
					publisher:send(k..' ', zmq.SNDMORE)
					publisher:send(cjson.encode({'cov', {pattern=pattern, path=path, value=value}}))
				end
			end
		end
	end
end

local function update(ns)
	for pattern, v in pairs(ptable) do
		for from, _ in pairs(v) do
			publisher:send(from..' ', zmq.SNDMORE)
			publisher:send(cjson.encode({'update', {pattern=pattern, namespace=ns}}))
		end
	end
end

local function write(path, value, from)
	-- TODO: send to 
	local namespace = path:match('^([^/]+)/')
	publisher:send(namespace..' ', zmq.SNDMORE)
	publisher:send(cjson.encode({'write', {path=path, value=value, from=from}}))
	return true
end

local function command(path, args, from)
	local namespace = path:match('^([^/]+)/')
	publisher:send(namespace..' ', zmq.SNDMORE)
	publisher:send(cjson.encode({'command', {path=path, args=args, from=from}}))
	return true
end

local function sub(pattern, from)
	local err =  'Invalid/Unsupported subscribe request'
	if pattern and from then
		log:info('IOBUS', 'subscribe '..pattern..' for '..from)
		ptable[pattern] = ptable[pattern] or {}
		ptable[pattern][from] = true
		return true
	end
	return false, err
end

local function unsub(pattern, from)
	local err =  'Invalid/Unsupported unsubscribe request'
	if not from then 
		return false, err
	end
	if pattern and from then
		if ptable[pattern] and ptable[pattern][from] then
			log:info('IOBUS', 'unsubscribe '..pattern..' for '..from)
			ptable[pattern][from] = nil
		end
	end
	return true
end

return {
	init = init,
	cov = cov,
	sub = sub,
	unsub = unsub,
	write = write,
	command = command,
	update = update,
}
