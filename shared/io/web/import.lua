local apps_folder = os.getenv('CAD_APPS_DIR') or '/tmp/apps'
local tmp_folder = os.getenv('CAD_TEMP_DIR') or '/tmp/upload'

local name = cgilua.POST.name
local port = cgilua.POST.port

if not name or not port then
	cgilua.print('<br> Incorrect POST found, we need the applicatoin\'s name and port')
end

local f = cgilua.POST.file

if f and next(f) then
	local _, name = cgilua.splitonlast(f.filename)
	local file = f.file

	local tmp_file = tmp_folder..'/'..name
	local dest, err = io.open(tmp_file, "wb")
	if dest then
		local bytes = file:read("*l")
		local filelen = 0
		while bytes do
			filelen = filelen + string.len(bytes) + 1
			dest:write(bytes)
			bytes = file:read("*l")
		end
		dest:close()

		-- Let app import the file
		local api = require('shared.api.app').new(port)
		local r, err = api:import(tmp_file)

		cgilua.print("<br> Upload OK ", tmp_file, " Size - ", filelen)
		if r then
			cgilua.print("<br> Import file successfully")
		else
			cgilua.print("<br>", err)
		end
	else
		cgilua.print("Failed to save file, error", err)
	end
end

