cjson = require 'cjson.safe'
return{
	get = function(req, res)
	assert (app.appname)
	local commands={}
	local mon= require 'shared.api.mon'
	local status, err = mon.query({app.appname})
		if status and status[app.appname] then
			local api = require 'shared.api.app'
			local client = api.new(status[app.appname].port)
			local reply, err = client:request('list_commands', {})
		if reply then
			commands = reply
		else
			info = err
		end
	res:ltp('test.html', {lwf=lwf, app=app, commands=SIGNAL, info=info})
	end
end
}
