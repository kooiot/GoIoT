
require 'shared.zhelpers'
local zmq = require 'lzmq'

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
	-- publish changes
	if ptable[path] then
		for k, v in pairs(ptable[vars.name]) do
			--log:debug('DATACACHE', 'Publish data changes for '..vars.name)
			publisher:send(k..' ', zmq.SNDMORE)
			publisher:send(cjson.encode(vars))
		end
	end
end

local function sub(path, from)
	local err =  'Invalid/Unsupported subscribe request'
	if path and from then
		ptable[path] = ptable[path] or {}
		ptable[path][id] = true
		return true
	end
	return false, err
end

local function unsub(from)
	local err =  'Invalid/Unsupported unsubscribe request'
	if not from then 
		return false, err
	end
	for k,v in pairs(ptable) do
		if ptable[v] and ptable[v][from] then
			log:info('DATACACHE', 'unsubscribe '..v..' for '..from)
			ptable[v][from] = nil
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
