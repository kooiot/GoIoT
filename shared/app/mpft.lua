--- Message process fucntion table
-- @local
--
local cjson = require 'cjson.safe'

local mpft = {}

----
local function call_handler(name, app, vars)
	if app.handlers[name] then
		return app.handlers[name](app, vars)
	end
	return nil, name.." not implemented"
end

mpft['version'] = function(app, vars)
	local reply = {
		'version',
		{
			version = app.version,
			build = app.build,
		}
	}
	app.server:send(cjson.encode(reply))
end

mpft['status'] = function(app, vars)
	local status, err = call_handler('on_status', app, vars)
	local reply = { 'status', status, err}
	app.server:send(cjson.encode(reply))
end

--- Pause the work loop function
mpft['pause'] = function(app, vars)
	local r, err = call_handler('on_pause', app, vars)
	local reply = { 'pause', r, err}
	app.server:send(cjson.encode(reply))
end

--- Close current application
mpft['close'] = function(app, vars)
	local r, err = call_handler('on_close', app, vars)
	local reply = { 'close', r, err}
	app.server:send(cjson.encode(reply))
end

--- Reload the application's configruation
mpft['reload'] = function(app, vars)
	local r, err = call_handler('on_reload', app, vars)
	local reply = { 'reload', r, err}
	app.server:send(cjson.encode(reply))
end

-- Get the application meta information
mpft['meta'] = function(app, vars)
	local meta = app:meta()
	--print(require('shared.util.PrettyPrint')(meta))
	local reply = {'meta', meta=meta}

	--print(cjson.encode(reply))
	app.server:send(cjson.encode(reply))
end

return mpft
