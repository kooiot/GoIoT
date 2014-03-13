
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
	log:debug('IOBUS', 'Publish data changes for '..path)
	local devpath = path:match('^([^/]-/[^/]-)')
	local t = ptable[devpath]
	-- publish changes
	if t then
		for k, v in pairs(t) do
			if k ~= devpath then
				publisher:send(k..' ', zmq.SNDMORE)
				publisher:send(cjson.encode({'cov', {devpath=devpath, path=path, value=value}}))
			end
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

local function sub(devpath, from)
	local err =  'Invalid/Unsupported subscribe request'
	if devpath and from then
		ptable[devpath] = ptable[devpath] or {}
		ptable[devpath][from] = true
		return true
	end
	return false, err
end

local function unsub(devpath, from)
	local err =  'Invalid/Unsupported unsubscribe request'
	if not from then 
		return false, err
	end
	if devpath and from then
		if ptable[devpath] and ptable[devpath][from] then
			log:info('IOBUS', 'unsubscribe '..devpath..' for '..from)
			ptable[devpath][from] = nil
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
	command = command
}
