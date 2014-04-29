return {
	get = function(req, res)
		lwf.ctx.session:set('advance', 'true')
		res.headers.location='/'
		res:ltp('jump.html')
	end
}
