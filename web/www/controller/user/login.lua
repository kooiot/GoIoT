
return {
	get = function(req, res)
		res:ltp('login.html')
	end,
	post = function(req, res)
		req:read_body()
		local username = req:get_post_arg('username')
		local password = req:get_post_arg('password')
		local r, err
		if username and password then
			r, err = app:authenticate(username, password)
			--[[
			if r then
				return res:redirect('/', 303)
			end
			]]--
		else
			err = 'Incorrect Post Message!!'
		end
		res:ltp('login.html', {app=app, lwf=lwf, err=err})
	end
}
