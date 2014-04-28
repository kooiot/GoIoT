
return {
	get = function(req, res)
		if lwf.ctx.user then
			res:ltp('system/upgrade.html')
		else
			res:redirect('/login')
		end
	end,
}
