local delay_exec = require 'shared.delay_exec'
local platform = require 'shared.platform'

local filetype = cgilua.POST.filetype

if not filetype then
	cgilua.print('<br> Incorrect POST found, we need the filetype')
else
	local f = cgilua.POST.file

	if f and type(f) == 'table' and next(f) then
		local _, name = cgilua.splitonlast(f.filename)
		local file = f.file

		local tmp_file = platform.path.temp..'/'..name
		local dest, err = io.open(tmp_file, "wb")
		if dest then
			local bytes = file:read("*a")
			dest:write(bytes)
			dest:close()
			--uploaded: 05.jpg (49467 bytes)
			cgilua.print("<br> Uploaded "..name.." ("..string.len(bytes).." bytes)")

			if filetype == 'sys' then
				local mv = 'mv '..tmp_file..' '..platform.path.core..'/'..name
				delay_exec('upgrade.sh', {'cd /', '$CAD_DIR/run.sh stop', 'umount /tmp/cad2', mv, 'sleep 3', 'reboot'})
				cgilua.print('<br> Device is rebooting to upgrade the system....')
			elseif filetype == 'app' then
				local appname = cgilua.POST.appname

				if not appname or string.len(appname) == 0 then
					cgilua.print('<br> Incorrect POST found, we need the appname')
					appname = "example"
				end
				local install = require 'shared.app.install'
				install(tmp_file, platform.path.apps, appname)

				-- remove temp file
				os.remove(tmp_file)
				cgilua.print('<br> Installed finished!')
			else
				cgilua.print('<br> Incorrect file type')
				-- remove temp file
				os.remove(tmp_file)
			end
		else
			cgilua.print("<br> Failed to save file, error", err)
		end
	else
		cgilua.print("<br> Please select a local file first")
	end
end
