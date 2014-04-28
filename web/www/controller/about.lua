
return {
	get = function(req, res)
		if not lwf.ctx.user then
			res:redirect('login')
		else
			local shared = app.model:get('shared')
			assert(shared)
			res:ltp('about.html', {lwf=lwf, app=app, sysinfo=shared.require('util.sysinfo')})
		end
	end
}
