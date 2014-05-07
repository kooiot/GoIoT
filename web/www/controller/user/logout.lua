local function doi(req, res)
	if lwf.ctx.user then
		lwf.ctx.user:logout()
	end
	res.headers.location='/user/login'
	--res:ltp('login.html')
	res:ltp('jump.html')
end

return {
	post = doi,
	get = doi,
}
