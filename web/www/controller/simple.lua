return {
	get = function(req, res)
		lwf.ctx.session:set('advance', 'false')
		res:ltp('index.html')
	end
}
