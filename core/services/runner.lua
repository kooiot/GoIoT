local execute = require 'shared.compat.execute'
local _M = {}

local function pid_file(name)
	return '/tmp/services.'..name..'.pid'
end

function _M.run(name, luafile)
	assert(name, luafile)
	local pidfile = pid_file(name)
	local pid = 0
	local r, code = execute('start-stop-daemon --start --make-pidfile --pidfile '..pidfile..' --background --chdir $CAD_DIR/core/services --startas /usr/bin/lua -- run.lua '..luafile..' "'..name..'"')
	if not r or code ~= 0 then
		return nil, 'Same name services has been runned'
	end

	local count = 32
	while count > 0 do
		--- the pid file may not ready,  right after the start-stop-daemon.
		execute('sleep 0')
		local r, code = execute('cat '..pidfile)
		if r and code == 0 then
			break
		end
		count = count - 1
	end
	local f, err = io.open(pidfile)
	if f then
		local s = f:read('*a')
		f:close()
		pid = tonumber(s)
		if not pid then
			err = 'pid file is empty????'
		end
		return pid, err
	else
		return nil, err
	end
end

function _M.abort(name)
	assert(name)
	local pidfile = pid_file(name)
	local r, code = execute('start-stop-daemon --stop --pidfile '..pidfile..' --retry 5')
	if not r or code ~= 0 then
		-- Do not remove the pid when aborting services, keep it..
		--os.remove(pidfile)
		return nil, code
	end
	return true
end

function _M.check(name)
	assert(name)
	local pidfile = pid_file(name)
	local r, code = execute('start-stop-daemon --status --pidfile '..pidfile)
	if not r or code ~= 0 then
		os.remove(pidfile)
		return nil, code
	end
	return true
end

return _M
