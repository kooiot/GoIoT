local function doi(req, res, info)
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

	rules = rules or { ['test1/unit.1/inputs/data2'] = {
[[ return function(path, value, client) local last_value = GET_LAST_VALUE(path, value.value) if last_value == value.value then return end if value.value == 1 then SEND_CMD('gree\/GREE\/commands\/开机', {'GREE\/开机'}) end end ]]}}

	rules = cjson.encode(rules)

	res:ltp('index.html', {lwf=lwf, app=app, rules=rules, commands=commands, inputs=inputs, info=info})
end
return {
	get = 	doi,
	post = function(req, res)
		local cjson = require 'cjson.safe'

		local rules = req:get_arg('rules')
		if not rules then
			res:write("incorrect post")
			return
		end
		rules, err = cjson.decode(rules)
		if not rules then
			res:write(err)
			return
		end

		local appapi = require 'shared.api.app'
		local port, err = appapi.find_app_port(app.appname)
		if not port then
			res:write(err or 'Error when trying to find application mgr port')
		else
			local client = appapi.new(port)
			local r, err = client:request('set_rule', rules)
			if r then
				res:write('Done, you need restart the application mannually')
			else
				res:write(err..' '.. app.appname)
			end
		end
	end
}
