return {
	get = function(req, res, appname)
		if not lwf.ctx.user then
			res:redirect('/')
			return
		end

		local appname = appname or req:get_arg('app')
		if not appname then
			res:redirect('/')
			return
		end

		local list = require 'shared.app.list'
		local log = require 'shared.log'
		local store = require 'shared.store'

		list.reload()
		local info = list.find(appname) 
		--- Check the version from cache only
		local app, err = store.find(info.path)
		local new_version = nil
		if app.info.version ~= info.version then
			new_version = app.info.version
		end
		if not info then
			res:ltp('jump.html', {timeout = 2, contents = 'The application['..appname..'] is not installed!! Will be redirected within three seconds'})
		else
			res:ltp('app/detail.html', {app=app, lwf=lwf, appname=appname, info=info, new_version=new_version})
		end
	end
}
