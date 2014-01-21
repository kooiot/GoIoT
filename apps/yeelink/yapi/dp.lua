
local yapi = require 'yapi.api'

local function api(devid, senid, method, obj, path)
	local path = '/v1.0/device/'..devid..'/sensor/'..senid..'/'..(path or 'datapoints')
	return yapi.call(method, obj, path)
end

local _M = {}

function _M.add(devid, senid, timestamp, value)
	local timestamp = timestamp or os.time()
	local obj = {
		timestamp = os.date('%FT%T', timestamp),
		value = value
	}
	local r, code = api(devid, senid, 'POST', obj)
	if code ~= 200 then
		return nil, 'Failed to save datapoint '..code
	end
	return true
end

function _M.adds(devid, senid, vals)
	local objs = {}
	for k, v in pairs(vals) do
		local timestamp = v.timestamp or os.time()
		local obj = {
			timestamp = os.date('%FT%T', timestamp),
			value = v.value
		}
		table.insert(objs, obj)
	end
	local r, code = api(devid, senid, 'POST', objs)
	if code ~= 200 then
		return nil, 'Failed to save datapoint '..code
	end
	return true
end

function _M.modify(devid, senid, timestamp, value)
	local obj = {
		value = value
	}
	local r, code = api(devid, senid, 'PUT', obj, 'datapoint/'..os.date('%FT%T', timestamp))
	if code ~= 200 then
		return nil, 'Failed to modify sensor '..code
	end

	return true
end


return _M
