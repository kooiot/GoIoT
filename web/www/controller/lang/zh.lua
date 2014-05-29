return {
	get = function(req, res)
		if not lwf.ctx.session then
			res:redirect('/')
		end

		lwf.ctx.session:set('lang', 'zh_CN')
		res.headers.location='/'
		local url = req.headers.Referer
		if url:len() == 0 then
			url = nil
		end
		res:ltp('jump.html', {timeout = 2, contents = '语言已经切换至中文...', url=url})
	end
}
