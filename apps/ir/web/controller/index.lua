local function doi(req, res, info)
	assert(app.appname)
	local commands = {}
	local mon = require 'shared.api.mon'
	local reply, err = mon.query({app.appname})
	if reply then
		local api = require 'shared.api.app'
		if reply.status and reply.status[app.appname] then
			local client = api.new(reply.status[app.appname].port)
			local reply, err = client:request('list_commands', {})
			if reply then
				commands = reply.commands
			end
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
			local cjson = require 'cjson.safe'
			local signal = cjson.decode(command)
			signal = signal or command
			local iobus = require 'shared.api.iobus.client'
			local path = app.appname..'/ir/commands/send'
			local client = iobus.new('web')
			client:command(path, signal)
		else
			info = "incorrect post"
		end
		res:write(info)
	end
}
