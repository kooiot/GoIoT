return {
	post = function(req, res)
		if not lwf.ctx.user then
			res:write('Not logined')
		end
		req:read_body()

		local filetype = req:get_post_arg('filetype', 'app')

		if not filetype then
			res:write('<br> Incorrect POST found, we need the filetype')
		else
			local file = req.post_args['file']

			if file and type(file) == 'table' and next(file) then
				local _, name = string.match(file.name, "^(.-)([^:/\\]*)$")

				local shared = app.model:get('shared')
				local platform = shared.require('platform')
				local delay_exec = shared.import('util.delay_exec')

				local tmp_file = platform.path.temp..'/'..name
				local dest, err = io.open(tmp_file, "wb")
				if dest then
					dest:write(file.contents)
					dest:close()
					res:write("<br> Uploaded "..name.." ("..string.len(file.contents).." bytes)")

					if filetype == 'sys' then
						local mv = 'mv '..tmp_file..' '..platform.path.core..'/'..name
						delay_exec('upgrade.sh', {'cd /', '$CAD_DIR/run.sh stop', 'umount /tmp/cad2', mv, 'sleep 3', 'reboot'})
						res:write('<br> Device is rebooting to upgrade the system....')
					elseif filetype == 'app' then
						local appname = req.get_post_arg('appname', '')

						if not appname or string.len(appname) == 0 then
							res:write('<br> Incorrect POST found, we need the appname')
							appname = "example"
						end
						local install = app.model:get('install')
						install(tmp_file, platform.path.apps, appname)

						-- remove temp file
						os.remove(tmp_file)
						res:write('<br> Installed finished!')
					else
						res:write('<br> Incorrect file type')
						-- remove temp file
						os.remove(tmp_file)
					end
				else
					res:write("<br> Failed to save file, error:"..err)
				end
			else
				res:write("<br> Please select a local file first")
			end
		end
	end
}
