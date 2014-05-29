local function doi(req, res, info)
	local commands = {}
	local mon = require 'shared.api.mon'
	local reply, err = mon.query({app.appname})
	if reply then
		local api = require 'shared.api.app'
		for k, v in pairs(reply.status) do
			print(k, v)
		end
		local client = api.new(reply.status[app.appname].port)
		local reply, err = client:request('list_commands', {})
		if reply then
			commands = reply.commands
		end
	end

	res:ltp('index.html', {lwf=lwf, app=app, commands=commands, info=info})
end
return {
	get = 	doi,
	post = function(req, res)
		local info = 'DONE'
		local command = req:get_arg('command')
		if command and string.len(command) ~= 0 then
			local iobus = require 'shared.api.iobus.client'
			local path = app.appname..'/ir/commands/'..command
			local client = iobus.new('web')
			client:command(path, {})
		else
			info = "incorrect post"
		end
		res:write(info)
	end
}
