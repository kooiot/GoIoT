return {
	get = function(req, res)
		if not lwf.ctx.user then
			res:redirect('/user/login')
		else
			res:ltp('store/settings.html')
		end
	end
}
