
return {
	get = function(req, res)
		if lwf.ctx.user then
			res:ltp('system/backup.html')
		else
			res:redirect('/login')
		end
	end,
}
