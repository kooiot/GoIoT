-- clear

local parser = require('shared.io.data.path').parser

local devices = {}

local tree = {}

tree.enum = function(path)
	local obj = parser(path)
	if not obj then return nil, 'Not found object for path '..path end

	return obj
end

tree.get = function(path, from)
	local obj = parser(path)
	if not obj then return nil, 'Not found object for path '..path end

	local value = {}
	for k, v in pairs(obj) do value[k] = v end
	value.path = path

	return value
end

tree.set = function(path, value, from)
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

tree.subscribe = function(path, from)
	local obj = parser(path)
	if not obj then return nil, 'Not found object for path '..path end
	if not obj['type'] then
		return nil, 'Only device and object could be subscribed'
	end

	obj.subscribes = obj.subscribes or {}
	table.insert(obj.subscribes, from)

	return true
end

tree.unsubscribe = function(path, from)
	local obj = parser(path)
	if not obj then return nil, 'Not found object for path '..path end
	--[[
	if not obj['type'] then
		return nil, 'Only device and object could be subscribed'
	end
	]]--

	for i, v in ipairs(obj.subscribes) do
		if v == from then
			return table.remove(obj.subscribes, i)
		end
	end

	return true
end

return {
	tree = tree,
	init = function(devs)
		devices = devs
	end,
}

