--- Devices interfaces for IO Application
-- @author Dirk Chang
--

local device = require 'shared.io.devs.device'
local pub = require 'shared.io.devs.pub'
local cjson = require 'cjson.safe'

--- Class Module
-- @type class
local class = {}

--- Add new device
-- @tparam string name Device name
-- @tparam string desc Device description
-- @tparam string virtual Device type (virtual or real device)
-- @treturn device Device Object
function class:add(name, desc, virtual)
	assert(not self.devices[name], 'Please check device existing before calling add')
	-- Device
	local dev = device(self.namespace, name, desc, virtual)
	self.devices[name] = dev
	return dev
end

--- Get the device by name
-- @tparam string name Device name
-- @treturn device Device Object
function class:get(name)
	return self.devices[name]
end

--- Get device name list
-- @treturn table Device name list (string table)
function class:list()
	local names = {}
	for k, v in pairs do
		table.insert(names, k)
	end
	return names
end

--- Bind COV callback function
-- @tparam function func COV callback functions
function class:bindcov(func)
	--@todo TODO: FIXME: currently all devices namespaces are binded
	pub.bind(func)
end

--- Save devices to json text
-- @treturn string Json text string
function class:save()
	local data = {namespace = self.namesapce, devices = self.devices}
	local json_text = cjson.encode(data)
	return json_text
end

--- Load devices from json text
-- @tparam string json Json text string
-- @treturn boolean ok
-- @treturn string error message
local function load(json)
	local data, err = cjson.decode(json_text)
	if not data then
		return nil, err
	end

	return true
end

--- Module function
-- @section

--- Create new interfaces
-- @tparam string namespace Namespace for all devices
-- @treturn class Interface object
local function new(namespace)
	local obj = {
		namespace = namespace,
		devices = {},
	}

	return setmetatable(obj, {__index=class})
end

---
--@export
return {
	new = new,
	load = load,
}

