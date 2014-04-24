--- Event message process fucntion table
-- @local
--
local empft = {}

----
local function call_handler(name, app, vars)
	if app.handlers[name] then
		return app.handlers[name](app, vars)
	end
	return nil, "Not implemented"
end

empft['pause'] = function(app, event)
	local r, status = call_handler('on_status', app, vars)
end

empft['close'] = function(app, event)
	local r, status = call_handler('on_close', app, vars)
end

empft['reload'] = function(app, event)
	local r, status = call_handler('on_reload', app, vars)
end

empft['info'] = function(app, event)
	local r, status = app.send_notice()
end

return empft
