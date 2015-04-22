
local http = require 'socket.http'
local ltn12 = require 'ltn12'
local url = require 'socket.url'

local _M = {
	ON = 'ON',
	OFF = 'OFF',
}

local function api(ip, path, param)
	assert(path)
	local fpath = 'http://'..ip..'/'..path
	if param then
		fpath = fpath..'?'..param
	end
	--print(fpath)
	local u = url.parse(fpath, {path=path, scheme='http'})

	local re = {}

	u.source = nil
	u.sink, re = ltn12.sink.table(re)
	u.method = method
	u.headers = {}
	u.headers["content-length"] = 0
	u.headers["content-type"] = "application/json;charset=utf-8"

	local r, code, headers, status = http.request(u)
	--print(r, code)--, pp(headers), status)

	if r and code == 200 then
		return true, table.concat(re)
	else
		local err = 'Error: code['..(code or 'Unknown')..'] status ['..(status or '')..'] url-'..path
		print(err)
		return nil, err
	end
end



--- Initialize the api, and set the write/command callback function
_M.init = function(timeout)
	http.TIMEOUT = timeout or 5
	load_conf()
end

_M.state = function(ip, cgi)
	local r, re = api(ip, cgi, 'state')
	if not r then
		return nil, re
	end

	if _M.ON == re:upper() then
		return true, _M.ON
	end
	if _M.OFF == re:upper() then
		return true, _M.OFF
	end

	return false, re:upper()
end

_M.change = function(ip, cgi, state)
	local r, re = api(ip, cgi, state:lower())
	if not r then
		return nil, re
	end
	return re:lower() == state:lower(), re:upper()
end

--- Keep the device online?
_M.ping = function(ip)
	return true
end

_M.relay = function(ip) return _M.state(ip, 'relay.cgi') end
_M.relay_on = function(ip) return _M.change(ip, 'relay.cgi', 'on') end
_M.relay_off = function(ip) return _M.change(ip, 'relay.cgi', 'off') end
_M.light = function(ip) return _M.state(ip, 'light.cgi') end
_M.light_on = function(ip) return _M.change(ip, 'light.cgi', 'on') end
_M.light_off = function(ip) return _M.change(ip, 'light.cgi', 'off') end
_M.power = function(ip)
	local r, err = _M.state(ip, 'power.cgi')
	if not r then
		return nil, err
	end

	return r:match('(%g+) (%g+) (%g+)')
end

return _M
