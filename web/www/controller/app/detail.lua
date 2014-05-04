return {
	get = function(req, res, appname)
		if not lwf.ctx.user then
			lwf.redirect('/')
			return
		end

		local appname = appname or req:get_arg('app')
		if not appname then
			lwf.redirect('/')
			return
		end

		local list = require 'shared.app.list'
		local log = require 'shared.log'

		if not list.find(appname) then
			res:ltp('jump.html', {timeout = 2, contents = 'The application['..appname..'] is not installed!! Will be redirected within three seconds'})
		else
			res:ltp('app/detail.html', {app=app, lwf=lwf, appname=appname})
		end
	end
}
