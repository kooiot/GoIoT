return {
	get = function(req, res)
		if not lwf.ctx.session then
			res:redirect('/')
		end

		lwf.ctx.session:set('lang', 'zh_CN')
		res.headers.location='/'
		res:ltp('jump.html', {timeout = 2, contents = '语言已经切换至中文...'})
	end
}
