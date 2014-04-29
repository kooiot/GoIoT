return {
	get = function(req, res)
		lwf.ctx.session:set('advance', 'true')
		res:ltp('index.html')
	end
}
