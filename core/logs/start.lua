#!/usr/bin/env lua

local file, err = io.open('/tmp/logs_logs', 'w+')

local f, err =  loadfile('main.lua')
if not f then
	file:write('Failed to compile application['..pwd..']:'..err)
else
	local r, err = pcall(f)

	if not r then
		file:write(err)
	end
end

file:close()
