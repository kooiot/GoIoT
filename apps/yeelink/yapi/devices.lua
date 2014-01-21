#!/usr/bin/env lua

local yapi = require 'yapi.api'

local function api(method, obj, path)
	local path = '/v1.0/'..(path or 'devices')
	return yapi.call(method, obj, path)
end

local _M = {}

--]]
function _M.create(title, about, location, tags)
	local obj = {
		title = title,
		about = about,
		location = location or {
			['local'] = 'Beijing',
			longitude  = '116.3333272934',
			latitude = '40.069922328756',
		},
		tags = tags or {}
	}

	local r, err = api('POST', obj)
	if r then
		return r.device_id
	end
	return nil, err
end

function _M.modify(id, device)
	local r, code = api('PUT', device, 'device/'..id)
	if code ~= 200 then
		return nil, 'Failed to modify device '..code
	end
end

function _M.enum()
	local devices, err = api('GET', {})
	if not devices then
		return nil, err
	end
	return devices
end

function _M.get(id)
	local device, err = api('GET', {}, 'device/'..id)
	if not device then
		return nil, err
	end

	device = device[1]
	local tags = {}
	for tag in device.tags:gmatch('([^,]+),') do
		table.insert(tags, tag)
	end
	device.tags = tags
	return device
end

function _M.delete(id)
	local r, code = api('DELETE', {}, 'device/'..id)
	if code ~= 200 then
		return nil, 'Failed to delete device '..code
	end
	return true
end


function _M.find(name)
	local devices, err = _M.enum()
	if not devices then
		return nil, err
	end
	local matches = {}
	for k, v in pairs(devices) do
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

