
local device = require 'shared.io.devtree.device'
local pub = require 'shared.io.devtree.pub'
local cjson = require 'cjson.safe'

local class = {}

function class:add(name, desc, virtual)
	assert(not self.devices[name], 'Please check device existing before calling add')
	-- Device
	local dev = device(self.namespace, name, desc, virtual)
	self.devices[name] = dev
	return dev
end

function class:get(name)
	return self.devices[name]
end

function class:list()
	local names = {}
	for k, v in pairs do
		table.insert(names, k)
	end
	return names
end

function class:bindcov(func)
	-- TODO: FIXME: current all devices namespaces are binded
	pub.bind(func)
end


function class:save()
	local data = {namespace = self.namesapce, devices = self.devices}
	local json_text = cjson.encode(data)
	return json_text
end

local function load(json)
	local data, err = cjson.decode(json_text)
	if not data then
		return nil, err
	end

	return true
end

local function new(namespace)
	local obj = {
		namespace = namespace,
		devices = {},
	}

	return setmetatable(obj, {__index=class})
end

return {
	new = new,
	load = load,
}

