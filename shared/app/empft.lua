local mpft = {}

local function call_handler(name, app, vars)
	if app.handlers[name] then
		return app.handlers[name](app, vars)
	end
	return nil, "Not implemented"
end

mpft['pause'] = function(app, event)
	local r, status = call_handler('on_status', app, vars)
end

mpft['close'] = function(app, event)
	local r, status = call_handler('on_close', app, vars)
end

mpft['reload'] = function(app, event)
	local r, status = call_handler('on_reload', app, vars)
end

mpft['info'] = function(app, event)
	local r, status = app.send_notice()
end

return mpft
