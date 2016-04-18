return {
	get = function(req, res)
		if not lwf.ctx.user then
			return res:redirect('/user/login')
		end
		res:ltp('user/settings.html', {lwf=lwf, app=app})
	end,
	post = function(req, res)
		req:read_body()
		if not lwf.ctx.user then
			res:redirect('/user/login')
		else
			local auth = lwf.ctx.auth
			local username = lwf.ctx.user.username

			local action = req.post_args['action']
				--[[
			if action == 'avatar' then
				local file = req.post_args['file']
				local file_path = app.config.static..'upload/avatar/'
				os.execute('mkdir -p '..file_path)
				local filename = file_path..username..'.jpg'
				local f, err = io.open(filename, 'w+')
				if f then
					f:write(file.contents)
					f:close()
				end
				res:ltp('user/settings.html', {lwf=lwf, app=app, info=err})
			elseif action == 'passwd' then
				]]--
			if action == 'passwd' then
				local orgpass = req:get_arg('org_pass')
				local newpass = req:get_arg('new_pass')
				local newpass2 = req:get_arg('new_pass2')
				local err = nil
				if newpass ~= newpass2 then
					err = 'Password re-type is not same'
				else
					local r = auth:authenticate(tostring(username), tostring(orgpass))
					if not r then
						err = 'Original password failure'
					else
						r, err = auth:set_password(tostring(username), tostring(newpass))
					end
				end
				res:ltp('user/settings.html', {lwf=lwf, app=app, info=err})
			end
		end
	end,
}
