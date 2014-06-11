#!/usr/bin/lua

local directory = arg[1]
local out = arg[2]
assert(directory and out, 'Usage: '..arg[0]..' <directory> <output file>')

local lfs = require 'lfs'

local commands = {
}

local load_command_file = function(devname, path)
	local name = path:match('.*/([^/]+)$')
	name = name:match('^(.+)%.[^%.]*') or name
	print(name)

	local file, err = io.open(path, 'r')
	if not file then
		print(err)
		return
	end
	local cmd = file:read('*a')
	commands[devname] = commands[devname] or {}
	commands[devname][name] = cmd
	file:close()
end

local function load_device_folder(devname, directory)
	for file in lfs.dir(directory) do
		local path = directory..'/'..file
		if lfs.attributes(path, "mode") == "file" then
			load_command_file(devname, path)
		end
	end
end

for file in lfs.dir(directory) do
	local path = directory..'/'..file
	if lfs.attributes(path, "mode") == "directory" then
		if file ~= '.' and file ~= '..' then
			print(file)
			local devname = file
			load_device_folder(devname, path)
		end
	end
end

cjson = require 'cjson.safe'
local file, err = io.open(out, 'w+')
assert(file, err)
file:write(cjson.encode(commands))
file:close()

