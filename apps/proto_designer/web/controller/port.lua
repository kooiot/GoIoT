return {
	get = function(req, res)
		local sysinfo = require 'shared.util.sysinfo'
		local list = sysinfo.list_serial()
		local config = require 'shared.api.config'
		local port, err = config.get(app.appname..'.port')
		res:ltp('port.html', {lwf=lwf,app=app,list=list,port=port,info=err})
	end,
	post = function(req, res)
		local port = req:get_arg('port')
		if not port then
			res:write('Incorrect post')
		else
			local config = require 'shared.api.config'
			config.set(app.appname..'.port', port)
			res:write('DONE! Need to restart application to take the changes')
		end
	end,
}
