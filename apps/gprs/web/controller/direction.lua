return {
	get = function(req, res)
		res:ltp('direction.html', {lwf=lwf,app=app,list=list,port=port,info=err})
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
