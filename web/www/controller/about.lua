
return {
	get = function(req, res)
		if not lwf.ctx.user then
			res:redirect('/user/login')
		else
			local shared = app.model:get('shared')
			assert(shared)
			local system = shared.require('system')
			res:ltp('about.html', {lwf=lwf, app=app, sysinfo=shared.require('util.sysinfo'), version=system.version()})
		end
	end
}
