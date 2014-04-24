--- Device class 
--

local map = require 'shared.io.devs.map'
local prop = require 'shared.io.devs.prop'
local command =  require 'shared.io.devs.command'
local object = require 'shared.io.devs.object'

--- Class metatable
local class = {}

--- set the proper path for prop
local function newchild(obj, sub)
	return function(table, key, prop)
		prop.path = obj.path..'/'..sub..'/'..key
		rawset(table, key, prop)
	end
end

--- Create new device
-- @function module
-- @tparam string namespace Namespace for device
-- @tparam string name Device name
-- @tparam string desc Device description
-- @tparam boolean virtual Device type (virtual or real)
local new = function (namespace, name, desc, virtual)
	local props = map(prop)
	local objects = map(object)
	local commands = map(command)

	--- Device Fields
	-- @section
	local device = {
		path = namespace..'/'..name,
		name = name, 
		desc = desc,
		subscribers = {},
	}
	--- Map of properties
	-- @see io.devs.prop
	-- @see io.devs.map
	device.props = props.new(newchild(device, 'props'))

	--- Map of input object
	-- @see io.devs.object
	-- @see io.devs.map
	device.inputs = objects.new(newchild(device, 'inputs'))

	--- Map of output object
	-- @see device.inputs
	device.outputs = objects.new(newchild(device, 'outputs'))

	--- Map of value object
	-- @see device.inputs
	device.values = objects.new(newchild(device, 'values'))

	--- Map of commands
	-- @see io.devs.command
	-- @see io.devs.map
	device.commands = commands.new(newchild(device, 'commands'))

	return setmetatable(device, {__index=class})
end

--- 
return new
