
local cjson = require 'cjson.safe'

local class = {}

function class:add_device(name, desc, typ)
	-- Device
	local new = {
		name = name,
		desc = desc,
		['type'] = typ or 'device',
		inputs = {['type'] = typ or 'objects'},
		outputs = {['type'] = typ or 'objects'},
		values = {['type'] = typ or 'objects'},
		commands = {['type'] = typ or 'objects'},
	}
	new.path = '/'..name
	self.devices[name] = new

	return new
end

function class:add(path, name, desc, datatype)
	local obj = self.parser(path)

	local obj_type = obj['type']

	if obj_type == 'objects' then
		-- Object 
		new = { name = name, desc = desc, ['type'] = 'object', datatype = datatype or 'basic'}
	elseif obj_type == 'device' or obj_type == 'virtual_device' then
		-- Device attributes
		new = { name = name, desc = desc, ['type'] = 'attribute', unit='none', datatype = datatype}
	elseif obj_type == 'object' then
		-- Object attributes
		new = { name = name, desc = desc, ['type'] = 'attribute', unit='none', datatype = datatype}
	else
		return nil, 'Cloud not create stuff under path '..path
	end
	new.path = path..'/'..name
	obj[name] = new

	return new
end

function class:erase(path)
	local parent, name = path:match('(.+)/([^/]-)')
	if parent then
		local obj = self.parser(parent)
		if not obj then return nil, 'Not found object for path '..path end

		obj[name] = nil
	else
		devices[path] = nil
	end

	return true
end

function class:get(path)
	local obj = self.parser(path)
	if not obj then return nil, 'Not found object for path '..path end

	local value = {}
	for k, v in pairs(obj) do value[k] = v end
	value.path = path

	return value
end

function class:set(path, value)
	local obj = self.parser(path)
	if not obj then return nil, 'Not found object for path '..path end

	obj.timestamp = value.timestamp
	obj.value = value.value
	obj.unit = value.unit or obj.unit

	api.set(obj.path, obj.value, obj.timestamp, obj.unit)

	return true
end

function class:enum(path)
	local obj = self.parser(path)
	if not obj then return nil, 'Not found object for path '..path end
	return obj
end

function class:update(json)
	local devs = cjson.encode(json)
	local copy = require 'shared.copy'
	copy.inplace(copy, self.devices)
end

function class:tojson()
	local json_text = cjson.encode(self.devices)
	return json_text
end

local function new(namespace, json)
	local devs, err = cjson.decode(json_text)
	devs = devs or {}

	local obj = {
		devices = devs,
		namespace = namespace,
		parser = require('shared.io.data.path')(devs).parser,
		mpft = require('shared.io.data.mpft')(parser),
		api = require('shared.io.data.api')(namespace),
	}

	return setmetatable(obj, {__index=class})
end

return {
	new = new
}
