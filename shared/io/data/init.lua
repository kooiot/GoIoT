local path = require 'shared.io.data.path'
local tree = require 'shared.io.data.tree'
local cjson = require 'cjson.safe'

local devices = {}

local function init()
	local file = io.open('dtree.json', 'r')
	local json_text = file:read("*a")
	local devs, err = cjson.decode(json_text)
	file:close()
	if devs then
		devices = devs
	end
	tree.init(devices)
end

local function save()
	local file = io.open('dtree.json', 'w')
	local json_text = cjson.encode(devices)
	file:write(json_text)
	file:close()
end

return {
	init = init,
	save = save,
	path = path,
	tree = tree.tree,
}

