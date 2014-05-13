local _M = {}

local function pid_file(name)
	return '/tmp/services.'..name..'.pid'
end

function _M.run(name, luafile)
	assert(name, luafile)
	local pidfile = pid_file(name)
	local pid = 0
	local r, status, code = os.execute('start-stop-daemon --start --make-pidfile --pidfile '..pidfile..' --background --chdir $CAD_DIR/core/services --startas /usr/bin/lua -- run.lua '..luafile..' "'..name..'"')
	if not r or status ~= 'exit' or code ~= 0 then
		return nil, 'Same name services has been runned'
	end

	local f, err = io.open(pidfile)
	local count = 32
	while not f and count > 0 do
		--- the pid file may not ready,  right after the start-stop-daemon.
		os.execute('sleep 0')
		f, err = io.open(pidfile)
		count = count - 1
	end
	if f then
		local s = f:read('*a')
		pid = tonumber(s)
		return pid
	else
		return nil, err
	end
end

function _M.abort(name)
	assert(name)
	local pidfile = pid_file(name)
	local r, status, code = os.execute('start-stop-daemon --stop --pidfile '..pidfile..' --retry 5')
	if not r or status ~= 'exit' or code ~= 0 then
		return nil, code
	end
	return true
end

function _M.check(name)
	assert(name)
	local pidfile = pid_file(name)
	local r, status, code = os.execute('start-stop-daemon --status --pidfile '..pidfile)
	if not r or status ~= 'exit' or code ~= 0 then
		os.remove(pidfile)
		return nil, code
	end
	return true
end

return _M
