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

_M.add = function(json)
	local req = {"add", {namespace=_M.namespace, json}}
	return reply(client:request(cjson.encode(req), true))
end

_M.erase = function()
	local req = {"erase", {namespace=_M.namespace}}
	return reply(client:request(cjson.encode(req), true))
end

_M.set = function(path, val, timestamp, unit)
	local timestamp = timestamp or ztimer.absolute_time()
	local req = {'set', {namespace=_M.namespace, path=path, value={value=val, unit=unit, timestamp=timestamp}}}
	return reply(client:request(cjson.encode(req), true))
end

_M.sets = function(vals)
	local req = {'sets', {namespace=_M.namespace, pvs=vals}}
	return reply(client:request(cjson.encode(req), true))
end

_M.get = function(path)
	local req = {'get', {namespace=_M.namespace, path=path}}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

_M.enum = function(path)
	local req = {'enum', {namespace=_M.namespace, path=path}}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

_M.subscribe = function(paths)
	local req = {'subscribe', {namespace=_M.namespace, paths=paths}}
	local reply, err = client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
	end
	return reply, err
end

_M.unsubscribe = function(paths)
	local req = {'unsubscribe', {namespace=_M.namespace, paths=paths}}
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

return function(self_id)
	_M.namespace = self_id
end
