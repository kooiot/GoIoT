local rest = require 'rest'

local ioname = arg[1]

local _M = {
	ON = 'ON',
	OFF = 'OFF',
}

local function save_conf()
	local config = require 'shared.api.config'
	config.set(ioname..'.api.conf', cjson.encode({PUSH=PUSH}))
end

local function load_conf()
	local config = require 'shared.api.config'
	local r, err = config.get(ioname..'.api.conf')
	if r then
		local t, err = cjson.decode(r)
		if t then
			PUSH = t.PUSH
		end
	end
end

--- Initialize the api, and set the write/command callback function
_M.init = function(cfg)
	load_conf()
	rest.init(cfg.key, cfg.url, cfg.timeout, cfg.gzip)
end

_M.call = rest.call

_M.state = function()
	local r, re = rest.call('GET', nil, 'relay.cgi?state')
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

_M.switch = function(state)
	local r, re = rest.call('GET', nil, 'relay.cgi?'..state:lower())
	if not r then
		return nil, re
	end
	return re:lower() == state:lower(), re:upper()
end

--- Keep the device online?
_M.ping = function()
	return true
end

return _M
