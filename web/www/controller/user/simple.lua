return {
	get = function(req, res)
		lwf.ctx.session:set('advance', 'false')
		res.headers.location='/'
		res:ltp('jump.html')
	end
}
