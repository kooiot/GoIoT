
return {
	get = function(req, res)
		if not lwf.ctx.user then
			res:redirect('login')
		else
			local sysinfo = app.model:get('sysinfo')
			res:ltp('about.html', {lwf=lwf, app=app, sysinfo=sysinfo})
		end
	end
}
