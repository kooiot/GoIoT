
local yapi = require 'yapi.api'

local function api(devid, method, obj, path)
	local path = '/v1.0/device/'..devid..'/'..(path or 'sensors')
	return yapi.call(method, obj, path)
end

local _M = {}

function _M.create(devid, typ, title, about, tags, unit)
	local obj = {
		['type'] = typ,
		title = title,
		about = about,
		tags = tags or {},
		unit = unit or {},
	}
	local r, err = api(devid, 'POST', obj)
	if r then
		return r.sensor_id
	end
	return nil, err
end

function _M.modify(devid, id, sensor)
	local r, code = api(devid, 'PUT', sensor, 'sensor/'..id)
	if code ~= 200 then
		return nil, 'Failed to modify sensor '..code
	end

	return true
end

function _M.enum(devid)
	local sensors, err = api(devid, 'GET', {})
	if not sensors then
		return nil, err
	end
	return sensors
end

function _M.get(devid, id)
	local sensor, err = api(devid, 'GET', {}, 'sensor/'..id)
	if not sensor then
		return nil, err
	end
	sensor = sensor[1]

	sensor.unit = {
		name = sensor.unit_name,
		symbol = sensor.unit_symbol,
	}
	sensor.unit_name = nil
	sensor.unit_symbol = nil

	return sensor
end

function _M.delete(devid, id)
	local r, code = api(devid, 'DELETE', {}, 'sensor/'..id)
	if code ~= 200 then
		return nil, 'Failed to delete device '..code
	end
	return true
end

function _M.find(devid, name)
	local sensors = _M.enum(devid)
	local matches = {}
	for k, v in pairs(sensors) do
		if v.title == name then
			table.insert(matches, v.id)
		end
	end

	if #matches == 0 then
		return nil, 'No such device'
	else
		return matches
	end
end


return _M
