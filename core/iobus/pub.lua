
require 'shared.zhelpers'
local zmq = require 'lzmq'
local log = require 'shared.log'

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
	local devpath = path:match('([^/]-/[^/]-)$')
	local t = ptable[devpath]
	-- publish changes
	if t then
		for k, v in pairs(t) do
			if k ~= devpath then
				publisher:send(k..' ', zmq.SNDMORE)
				publisher:send(cjson.encode(vars))
			end
		end
	end
end

local function sub(path, from)
	local err =  'Invalid/Unsupported subscribe request'
	if path and from then
		ptable[path] = ptable[path] or {}
		ptable[path][from] = true
		return true
	end
	return false, err
end

local function unsub(path, from)
	local err =  'Invalid/Unsupported unsubscribe request'
	if not from then 
		return false, err
	end
	if path and from then
		if ptable[path] and ptable[path][from] then
			log:info('IOBUS', 'unsubscribe '..path..' for '..from)
			ptable[path][from] = nil
		end
	end
	return true
end

return {
	init = init,
	cov = cov,
	sub = sub,
	unsub = unsub
}
