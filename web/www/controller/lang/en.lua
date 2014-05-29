return {
	get = function(req, res)
		if not lwf.ctx.session then
			res:redirect('/')
		end

		lwf.ctx.session:set('lang', 'en_US')
		res.headers.location='/'
		local url = req.headers.Referer
		if url:len() == 0 then
			url = nil
		end
		res:ltp('jump.html', {timeout = 2, contents = 'Language has changed to English...', url=url})
	end
}
