
return {
	get = function(req, res)
		if lwf.ctx.user then
			res:ltp('system/upgrade.html')
		else
			lwf.exit(404)
		end
	end,
}
