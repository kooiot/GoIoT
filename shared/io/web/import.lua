local apps_folder = os.getenv('CAD_APPS_DIR') or '/tmp/apps'
local tmp_folder = os.getenv('CAD_TEMP_DIR') or '/tmp/upload'

local name = cgilua.POST.name
local port = cgilua.POST.port

if not name or not port then
	cgilua.print('<br> Incorrect POST found, we need the applicatoin\'s name and port')
end

local f = cgilua.POST.file

if f and type(f) == 'table' and next(f) then
	local _, name = cgilua.splitonlast(f.filename)
	local file = f.file

	local tmp_file = tmp_folder..'/'..name
	local dest, err = io.open(tmp_file, "wb")
	if dest then
		local filelen = 0
		for c in file:lines() do
			filelen = filelen + string.len(c) + 1
			dest:write(c)
			dest:write('\n')
		end
		dest:close()

		-- Let app import the file
		local api = require('shared.api.app').new(port)
		local r, err = api:import(tmp_file)

		--uploaded: 05.jpg (49467 bytes)
		cgilua.print("<br> Uploaded "..name.." ("..filelen.." bytes)")
		if r then
			cgilua.print("<br> Import file successfully")
		else
			cgilua.print("<br> Failed to import "..name, "<br> ERROR: "..err)
		end

		-- remove temp file
		os.remove(tmp_file)

		-- reload
		local r, err = api:reload()
		if r then
			cgilua.print("<br> Application reload successfully")
		else
			cgilua.print("<br> Failed to reload "..name, "<br> ERROR: "..err)
		end
	else
		cgilua.print("Failed to save file, error", err)
	end
else
	cgilua.print("Please select a local file first")
end

