#!/usr/bin/lua

local directory = arg[1]
local out = arg[2]
assert(directory and out, 'Usage: '..arg[0]..' <directory> <output file>')

local lfs = require 'lfs'

local commands = {
}

local load_command_file = function(path)
	local name = path:match('.*/([^/]+)$')
	name = name:match('^(.+)%.[^%.]*') or name
	print(name)

	local file, err = io.open(path, 'r')
	if not file then
		print(err)
		return
	end
	local cmd = file:read('*a')
	commands[name] = {name=name, cmd = cmd}
	file:close()
end

for file in lfs.dir(directory) do
	--- Cannot use the == 'file' as lfs cannot get the infomration of bin file correctly...
	if lfs.attributes(file, "mode") ~= "directory" then
		load_command_file(directory..'/'..file)
	end
end

cjson = require 'cjson.safe'
local file, err = io.open(out, 'w+')
assert(file, err)
file:write(cjson.encode(commands))
file:close()

