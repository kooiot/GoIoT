
local function doi(req, res)
		local climate = {temp="error"}
	assert (app.appname)
		local cjson = require 'cjson.safe'
	--	local climate = {city="city",temp1="temp1",temp2="temp2", temp="temp",weather="weather",WD="WD",WS="WS",SD="SD",WES="WES",time="time"}
		local appapi = require 'shared.api.app'
		local port, err = appapi.find_app_port(app.appname)
		if not port then
			res:write(err or 'Error when trying to find application mgr port')
		else
			local client = appapi.new(port)
			local r, err = client:request('climate_data', {})
				client:close()
			if r then
				climate = r.rules
			end
		end

		local conf={}
		local list_onlight = {"NULL"}
			for i=0, 1000,50 do
				list_onlight[#list_onlight+1] = i
			end
			list_onlight[#list_onlight+1]	 = 1024
		local config = require 'shared.api.config'
		local conf, err = config.get(app.appname..'.light') or
		[[	conf.onlight_less =  "NULL"
			
			conf.onlight_more =  "NULL"
			conf.command_less = "NULL"
			local config = require 'shared.api.config'
			config.set(app.appname..'.light', conf)
	]]	
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
		res:ltp('light.html', {lwf=lwf, app=app, list_onlight=list_onlight,conf=conf,commands=commands})

end


return {
	get = 	doi,
	post = function(req, res)

		local conf = {}
	---------------小于光照动作-------------------
		local onlight_less = req:get_arg('onlight_less')
	--------------大于光照动作--------------------
		local onlight_more = req:get_arg('onlight_more')
		local command_less = req:get_arg('command_less')
		if (not onlight_less)then
			conf.onlight_less =  onlight_less or "NULL"
			conf.onlight_more =  onlight_more or "NULL"
			conf.command_less =  command_less or "NULL"
			res:write('Incorrect post')
			
		else
			conf.onlight_more =  onlight_more or "NULL"
			conf.onlight_less =  onlight_less or "NULL"
			conf.command_less =  command_less or "NULL"
			local config = require 'shared.api.config'
			config.set(app.appname..'.light', conf)
			res:write('DONE')
		end


		local climate = {temp="error"}
		local cjson = require 'cjson.safe'

		local action = req:get_arg('action')
		if action == 'result' then

			local appapi = require 'shared.api.app'
			local port, err = appapi.find_app_port(app.appname)
			if not port then
				res:write(err or 'Error when trying to find application mgr port')
			else
				local client = appapi.new(port)
				local r, err = client:request('climate_data', {})
				client:close()
				if r then
					--res:write('Done, you need restart the application mannually')
					climate = r.rules
				else
					res:write(err..' '.. app.appname)
				end
			end
			res:write(climate)
		end 
		
	end
}

