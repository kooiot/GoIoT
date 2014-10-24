local cjson = require 'cjson.safe'
platform = require "shared.platform"
path_plat = platform.path.apps

local function doi(req, res)
	local path_plat = path_plat .. "/" .. app.appname .. "/config/" .. app.appname .. "/"
	local excute = "mkdir " .. path_plat .. " -p"
	if not os.execute(excute) then
		res:write(app.appname)
		return
	end
	local filename = path_plat .. app.appname .. "_config.json"
	local file, err = io.open(filename, "a+")

	if file then
		local config = file:read("*a")
		if config == "" then
			devices = {}
			t = {}
			table.insert(devices,t)
			config = cjson.encode(devices)
			file:write(config)
		end
		file:close()
		
		
	local api = require 'shared.api.iobus.client'
	local client = api.new('web')
	local cjson = require 'cjson.safe'

	local commands = {}
	local inputs = {}

	local nss, err = client:enum('.+')

	if nss then
		for ns, devs in pairs(nss) do
			local tree, err = client:tree(ns)

			if tree then
				for k, dev in pairs(tree.devices) do
					for k, v in pairs(dev.commands) do
						commands[#commands + 1] = {name=v.name, desc=v.desc, path=v.path}
					end
					for k, v in pairs(dev.inputs) do
						inputs[#inputs + 1] = {name = v.name, desc = v.desc, path=v.path}
					end
				end
			end
		end	
	else
		info = err
	end

	local rules = nil
	local appapi = require 'shared.api.app'
	local port, err = appapi.find_app_port(app.appname)
	if not port then
		res:write(err or 'Error when trying to find application mgr port')
	else
		local client = appapi.new(port)
		local r, err = client:request('get_rule', {})
		if r then
			rules = r.rules
		end
	end
	
	local conf={}
	local config_path = require 'shared.api.config'
	local conf, err = config_path.get(app.appname..'.read') or
	[[conf.path="/nill/nill/nill"]]

	rules = rules or { ['test1/unit.1/inputs/data2'] = {
[[ return function(path, value, client) local last_value = GET_LAST_VALUE(path, value.value) if last_value == value.value then return end if value.value == 1 then SEND_CMD('gree\/GREE\/commands\/开机', {'GREE\/开机'}) end end ]]}}

	rules = cjson.encode(rules)
--		res:write(config)
		res:ltp('index.html', {lwf=lwf, app=app, rules=rules, commands=commands, inputs=inputs,  conf=conf, data_data = 1, json_text=config})
end
end
return {
	get = 	doi,
	post = function(req, res)

		req:read_body()
		local path = path_plat .. "/" .. app.appname .. "/config/" .. app.appname .. "/"
		local filename = path .. app.appname .. "_config.json"
		res:write(app.appname)
		local t = {}
		t.config={}
		local ratio = req:get_post_arg("ratio")
		res:write(ratio)
		t.config.ratio = cjson.decode(ratio)

		local file, err = io.open(filename, "a+")
		if not file then
			res:write(err)
			return
		end
--		file:write(ratio)

		local json_text = file:read("*a")
		local tags = cjson.decode(json_text)
		local flags = false
		if tags then	
			tags = {}
			for k, v in pairs(tags)	do
				if v.config.ratio then
					tags[k] = t
					flags = true
			--		res:write ("*********************************")
					break
				end
			end
			if flags == false then
				table.insert(tags, t)
			end
		else
			table.insert(tags. t)
		end
	
		file:close()
		file = io.open(filename, "w")
		file:write(cjson.encode(tags))
--]]
		file:close()

	end
}

