return {
	get = function(req, res, appname)
		local appname = appname or req:get_arg('app')
		if not appname then
			lwf.redirect('/')
		else
			if not appname then
				lwf.redirect('/')
			else
				res:ltp('app/detail.html', {app=app, lwf=lwf, appname=appname})
			end
		end
	end
}
