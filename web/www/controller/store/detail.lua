return {
	get = function(req, res, appname)
		if not lwf.ctx.user then
			res:redirect('/user/login')
			return
		end

		local appname = appname or req:get_arg('app')
		if not appname then
			res:redirect('/store')
			return
		end

		res:ltp('store/detail.html', {app=app, lwf=lwf, appname=appname})
	end
}
