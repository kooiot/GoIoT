-- Virtual devices apis
--
--
local gen = require('shared.io.data.path').gen
local cjson = require 'cjson.safe'

local class = {}

function class:add_object(name, desc, datatype, attrs)
	local path = gen(self.dev.name, 'objects')
	local object = self.tree:add(path, name, desc, datatype) 
	for k, v in pairs(attrs) do
		local attr = self.tree:add(object.path, v.name, v.desc)
	end

	return object
end

function class:add_output(name, desc, datatype, attrs)
	local path = gen(self.dev.name, 'objects')
	local object = self.tree:add(path, name, desc, datatype) 
	for k, v in pairs(attrs) do
		local attr = self.tree:add(object.path, v.name, v.desc)
	end
	return object
end

function class:add_value(name, desc, datatype, attrs)
	local path = gen(self.dev.name, 'objects')
	local object = self.tree:add(path, name, desc, datatype) 
	for k, v in pairs(attrs) do
		local attr = self.tree:add(object.path, v.name, v.desc)
	end

	return object
end

function class:add_command(name, desc, args)
	local path = gen(self.dev.name, 'commands')
	local command = self.tree:add(path, name, desc)
	--[[
	for k, v in pairs(args) do
		local attr = self.tree:add(command.path, v.name, v.desc)
	end
	--]]
	local args = self.tree:add(command.path, 'args', cjson.encode(args))
	
	return command
end

function class:sync()
	-- TODO: Send current device tree
	
end

return function (tree) 
	local tree = tree
	return {
		new = function(name, desc, virtual)
			local typ = nil
			if virtual then
				typ = 'virtual_device'
			end
			local obj = {
				tree = tree,
				dev = tree:add_device(nil, name, desc, typ),
			}
			return setmetatable(obj, {__index=class})
		end,
	}
end
