--- The system module
--
local _M = {}

--- Get the current system version
-- @treturn string version string
_M.version = function()
	if _M.VERSION then
		return _M.VERSION
	end

	local platform = require 'shared.platform'
	local f, err = io.open(platform.path.cad..'/version')
	if f then
		_M.VERSION = f:read('*a')
		f:close()
	else
		_M.VERSION = '0.0.0.0'
	end
	return _M.VERSION
end

--- Upgrade system
--@param file file is the filename or a table contains {name, content}
--@treturn boolean the result
--@treturn string the information readable
_M.upgrade = function(file)
	local platform = require('shared.platform')
	local delay_exec = require('shared.util.delay_exec')

	if file and type(file) == 'table' and next(file) then
		--- Name is ignored
		--local name = string.match(file.name, "([^:/\\]+)$")

		local tmp_file = platform.path.temp..'/cad2.sfs'
		local dest, err = io.open(tmp_file, "wb")
		if not dest then
			return nil, "Failed to save file, error:"..err
		end

		dest:write(file.contents)
		dest:close()

		local mv = 'mv '..tmp_file..' '..platform.path.core..'/cad2.sfs'
		local start = 'mount '..platform.path.core..'/cad2.sfs '..platform.path.cad
		local umount = 'umount '..platform.path.cad
		delay_exec('upgrade.sh', {'cd /', platform.path.cad..'/run.sh stop', umount, mv, 'sleep 3', start, platform.path.cad..'/run.sh start'})
	elseif type(file) == 'string' then
		local f, err = io.open(file)
		if not f then
			return nil, err
		end

		local mv = 'mv '..file..' '..platform.path.core..'/cad2.sfs'
		local start = 'mount '..platform.path.core..'/cad2.sfs '..platform.path.cad
		local umount = 'umount '..platform.path.cad
		delay_exec('upgrade.sh', {'cd /', platform.path.cad..'/run.sh stop', umount, mv, 'sleep 3', start, platform.path.cad..'/run.sh start'})
	else
		return nil, "Please select a local file first"
	end

	return true, 'System will be restarted soon'
end

return _M
