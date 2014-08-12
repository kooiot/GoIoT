return {
	post = function(req, res)
		if not lwf.ctx.user then
			res:redirect('/user/login')
			return
		end
		req:read_body()

		local file = req.post_args['file']

		if file and type(file) == 'table' and next(file) then
			local name = string.match(file.name, "([^:/\\]+)$")

			local shared = app.model:get('shared')
			local platform = shared.require('platform')

			local tmp_file = platform.path.temp..'/'..name
			local dest, err = io.open(tmp_file, "wb")
			if dest then
				dest:write(file.contents)
				dest:close()
				res:write("<br> Uploaded "..name.." ("..string.len(file.contents).." bytes)")

				local appname = req:get_post_arg('appname')

				if not appname or string.len(appname) == 0 then
					res:write('<br> Incorrect POST found, we need the appname')
					appname = "example"
				end
				local install = shared.require('app.install')
				local r, err = install(tmp_file, platform.path.apps, appname)

				-- remove temp file
				os.remove(tmp_file)
				if r then
					res:write('<br> Installed finished!')
				else
					res:write('<br> Install error: '..err)
				end
			else
				res:write("<br> Failed to save file, error:"..err)
			end
		else
			res:write("<br> Please select a local file first")
		end
	end
}
