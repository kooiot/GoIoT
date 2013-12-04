#!/usr/bin/env lua

local m_path = os.getenv('CAD_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

require 'shared.zhelpers'

local cjson = require 'cjson.safe'

local CONF_FILE = 'conf.json'

local conf = nil

function load_conf()
	local file, err = io.open(CONF_FILE, "r")
	if file then
		local conf = cjson.decode(file:read("*a"))
		file:close()
		return conf
	end
	return nil, err
end

function save_conf()
	local file, err = io.open(CONF_FILE, "w+")
	if file then
		file:write(cjson.encode(conf))
		file:close()
		return true
	end
	return nil, err
end

conf = load_conf() or {
	{
		type = "core",
		name = "core",
	},
}

--[[
	{
		{
			type = "core",
			name = "rdb",
			path = 'app/rdb',
			program = 'start.lua',
			args = nil,
			restart = "function() restart(all) end"
			startup = "function() end"
			teardown = "function() end"
		},
		{
			type = 'app',
			name = 'rdb',
			path = 'app/test',
			program = 'start.lua',
			args = nil,
			restart = ture,
		},
		{
		....
		},
]]--

local function start_app(app)
	print('run app', app.name)
	-- TODO:
end

local function start(app) 
	for k, v in pairs(conf) do
		if not app or app == v.name then
			start_app(v)
		end
	end
end

local num = 3
while (num > 0) do
	start()
	sleep(1)
	num = num - 1
end

save_conf()
