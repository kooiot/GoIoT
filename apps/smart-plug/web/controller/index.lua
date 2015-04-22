return {
	get = 	function(req, res)
		assert(app.appname)
		local api = require 'shared.api.app'
		local port, err = api.find_app_port(app.appname)
		local devs = {}
		if port then
			local client = api.new(port)
			devs, err = client:request('list', {})
		end
		devs = devs or {}
		devs['test'] = {ip='11.1.1.1', ver=2}
		res:ltp('index.html', {lwf=lwf, app=app, devs=devs, info=err})
	end,
	post = function(req, res)
		local info = 'DONE'
		local command = req:get_arg('command')
		local name = req:get_arg('name')

		if command and string.len(command) ~= 0 and name and string.len(name) ~= 0 then
			local cjson = require 'cjson.safe'
			--[[
			local signal = cjson.decode(command)
			signal = signal or command
			local iobus = require 'shared.api.iobus.client'
			local path = app.appname..'/ir/commands/send'
			local client = iobus.new('web')
			client:command(path, signal)
			]]--
		else
			info = "incorrect post"
		end
		res:write(info)
	end
}
