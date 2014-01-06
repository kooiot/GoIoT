local delay_exec = require 'shared.delay_exec'

local apps_folder = os.getenv('CAD_APPS_DIR') or '/tmp/apps'
local core_folder = os.getenv('CAD_CORE_DIR') or '/tmp/core'
local tmp_folder = os.getenv('CAD_TEMP_DIR') or '/tmp/apps/_upload'

local filetype = cgilua.POST.filetype

if not filetype then
	cgilua.print('<br> Incorrect POST found, we need the filetype')
else
	local f = cgilua.POST.file

	if f and type(f) == 'table' and next(f) then
		local _, name = cgilua.splitonlast(f.filename)
		local file = f.file

		local tmp_file = tmp_folder..'/'..name
		local dest, err = io.open(tmp_file, "wb")
		if dest then
			local bytes = file:read("*a")
			dest:write(bytes)
			dest:close()
			--uploaded: 05.jpg (49467 bytes)
			cgilua.print("<br> Uploaded "..name.." ("..string.len(bytes).." bytes)")

			if filetype == 'sys' then
				--os.execute('mv '..tmp_file..' '..core_folder)
				local mv = 'cp '..tmp_file..' '..core_folder..'/'..name
				--delay_exec('upgrade.sh', {'$CAD_DIR/run.sh stop', mv, 'sleep 3', 'reboot'})
				delay_exec('upgrade.sh', {'cd /', '$CAD_DIR/run.sh stop', 'umount /tmp/cad2', 'sleep 1', mv, 'sleep 3', 'reboot'})
			elseif filetype == 'app' then
				local appname = cgilua.POST.appname

				if not appname or string.len(appname) == 0 then
					cgilua.print('<br> Incorrect POST found, we need the appname')
					appname = "example"
				end
				local install = require 'shared.app.install'
				install(tmp_file, apps_folder, appname)
			else
				cgilua.print('<br> Incorrect file type')
			end

			-- ATTENTION: FIXME: remove temp file
			os.remove(tmp_file)
		else
			cgilua.print("<br> Failed to save file, error", err)
		end
	else
		cgilua.print("<br> Please select a local file first")
	end
end
