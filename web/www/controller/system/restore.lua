return {
	get = function(req, res)
		res:recirect('/system/backup')
	end,
	post = function(req, res)
		if not lwf.ctx.user then
			res:redirect('/user/login')
			return
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
						delay_exec('upgrade.sh', {'cd /', '$KOOIOT_DIR/run.sh stop', 'umount /tmp/kooiot', mv, 'sleep 3', 'reboot'})
						res:write('<br> Device is rebooting to upgrade the system....')
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
