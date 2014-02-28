-- Data api access the datacache

require "shared.zhelpers"
local zmq = require "lzmq"
local cjson = require "cjson.safe"
local ztimer = require 'lzmq.timer'

local req = require "shared.req"
local client = req.new()

client:open()

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

_M.login = function(user, pass)
	local req = {"login", {user=user, pass=pass}}
	return reply(client:request(cjson.encode(req), true))
end

_M.set = function(path, value, timestamp, quality)
	local timestamp = timestamp or ztimer.absolute_time()
	local req = {'set', {path=path, value=value, timestamp=timestamp, quality=quality}}
	return reply(client:request(cjson.encode(req), true))
end

-- vals is the table that path, value(value, timestamp, quality)
_M.sets = function(vals)
	local req = {'sets', vals}
	return reply(client:request(cjson.encode(req), true))
end

_M.get = function(path)
	local req = {'get', {path=path}}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

_M.enum = function(pattern)
	local req = {'enum', {pattern=pattern}}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

_M.tree = function(path)
	local req = {'tree', {path=path}}
	return reply(client:request(cjson.encode(req), true))
end

_M.subscribe = function(self_id, paths)
	local req = {'subscribe', {id = self_id, paths=paths}}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

_M.unsubscribe = function(self_id)
	local req = {'unsubscribe', {id = self_id}}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

_M.version = function()
	local req = {'version'}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

return _M

