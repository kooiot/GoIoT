
local map = require 'shared.io.devs.map'
local prop = require 'shared.io.devs.prop'
local command =  require 'shared.io.devs.command'
local object = require 'shared.io.devs.object'

local class = {}


-- set the proper path for prop
local function newchild(obj, sub)
	return function(table, key, prop)
		prop.path = obj.path..'/'..sub..'/'..key
		rawset(table, key, prop)
	end
end

local new = function (namespace, name, desc, virtual)
	local props = map(prop)
	local objects = map(object)
	local commands = map(command)

	local dev = {
		path = namespace..'/'..name,
		name = name, 
		desc = desc,
		subscribers = {},
	}
	dev.props = props.new(newchild(dev, 'props'))
	dev.inputs = objects.new(newchild(dev, 'inputs'))
	dev.outputs = objects.new(newchild(dev, 'outputs'))
	dev.values = objects.new(newchild(dev, 'values'))
	dev.commands = commands.new(newchild(dev, 'commands'))

	return setmetatable(dev, {__index=class})
end

return new
