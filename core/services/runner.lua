local _M = {}

local function pid_file(name)
	return '/tmp/services.'..name..'.pid'
end

function _M.run(name, luafile)
	assert(name, luafile)
	local pidfile = pid_file(name)
	local pid = 0
	local r, status, code = os.execute('start-stop-daemon --start --make-pidfile --pidfile '..pidfile..' --background --chdir $CAD_DIR --startas /usr/bin/lua -- '..luafile)
	if not r or status ~= 'exit' or code ~= 0 then
		return nil, 'Same name services has been runned'
	end

	--- Do not open the pid file right after the start-stop-daemon, you will not get pid correctly
	os.execute('cat '..pidfile)

	local f, err = io.open(pidfile)
	assert(f, err)
	local s = f:read('*a')
	pid = tonumber(s)
	return pid
end

function _M.abort(name)
	assert(neme)
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
