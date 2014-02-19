
local path = require 'shared.io.data.path'
local cjson = require 'cjson.safe'

local _M = {}
local devices = {}

function _M.add(path, name, desc)
	local obj = path.parser(path)

	local obj_type = obj['type']

	local new = nil
	if obj_type == 'devices' then
		new = { name = name,
				desc = desc,
				['type'] = 'device',
				inputs = {['type'] = 'objects'},
				outputs = {['type'] = 'objects'},
				values = {['type'] = 'objects'}
			}
		obj[name] = new
	elseif obj_type == 'objects' then
		new = { name = name, desc = desc, ['type'] = 'object'}
		obj[name] = new
	elseif obj_type == 'device' then
		new = { name = name, desc = desc }
		obj[name] = new
	elseif obj_type == 'object' then
		new = { name = name, desc = desc }
		obj[name] = new
	else
		return nil, 'Cloud not create stuff under path '..path
	end

	return new
end

function _M.erase(path)
	local parent, name = path:match('(.+)/([^/]-)')
	if parent then
		local obj = path.parser(parent)
		if not obj then return nil, 'Not found object for path '..path end

		obj[name] = nil
	else
		devices[path] = nil
	end

	return true
end

function _M.get(path)
	local obj = parser(path)
	if not obj then return nil, 'Not found object for path '..path end

	local value = {}
	for k, v in pairs(obj) do value[k] = v end
	value.path = path

	return value
end

function _M.set(path, value)
	local obj = parser(path)
	if not obj then return nil, 'Not found object for path '..path end

	obj.timestamp = value.timestamp
	obj.value = value.value
	obj.unit = value.unit or obj.unit

	for i, v in ipairs(obj.subscribes) do
		-- TODO: Notice the data changes
	end

	return true
end

function _M.init(devs)
	devices = devs
end

