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
	return nil, "Not implemented"
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
	local r, status = call_handler('on_status', app, vars)
	if not r then
		status = 'running'
	end
	local reply = { 'status', {result=true, status = status}}
	app.server:send(cjson.encode(reply))
end

--- Pause the work loop function
mpft['pause'] = function(app, vars)
	local r, status = call_handler('on_pause', app, vars)
	local reply = { 'pause', {result=r, status = status}}
	app.server:send(cjson.encode(reply))
end

--- Close current application
mpft['close'] = function(app, vars)
	local r, status = call_handler('on_close', app, vars)
	local reply = { 'close', {result=r, status = status}}
	app.server:send(cjson.encode(reply))
end

--- Reload the application's configruation
mpft['reload'] = function(app, vars)
	local r, status = call_handler('on_reload', app, vars)
	local reply = { 'reload', {result=r, status = status}}
	app.server:send(cjson.encode(reply))
end

-- Get the application meta information
mpft['meta'] = function(app, vars)
	local meta = app:meta()
	--print(require('shared.PrettyPrint')(meta))
	local reply = {'meta', {result=true, meta=meta}}

	print(cjson.encode(reply))
	app.server:send(cjson.encode(reply))
end

return mpft
