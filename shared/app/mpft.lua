local cjson = require 'cjson.safe'

local mpft = {}

local function call_handler(name, obj, vars)
	if obj.handlers[name] then
		return obj.handlers[name](obj, vars)
	end
	return nil, "Not implemented"
end

mpft['version'] = function(obj, vars)
	local reply = {
		'version',
		{
			version = obj.version,
			build = obj.build,
		}
	}
	obj.server:send(cjson.encode(reply))
end

mpft['status'] = function(obj, vars)
	local r, status = call_handler('on_status', obj, vars)
	if not r then
		status = 'running'
	end
	local reply = { 'status', {result=true, status = status}}
	obj.server:send(cjson.encode(reply))
end

mpft['start'] = function(obj, vars)
	local r, status = call_handler('on_start', obj, vars)
	local reply = { 'start', {result=r, status = status}}
	obj.server:send(cjson.encode(reply))
end

mpft['stop'] = function(obj, vars)
	local r, status = call_handler('on_stop', obj, vars)
	local reply = { 'stop', {result=r, status = status}}
	obj.server:send(cjson.encode(reply))
end

mpft['reload'] = function(obj, vars)
	local r, status = call_handler('on_reload', obj, vars)
	local reply = { 'reload', {result=r, status = status}}
	obj.server:send(cjson.encode(reply))
end

-- Get the application meta information
mpft['meta'] = function(obj, vars)
	local meta = obj:meta()
	--print(require('shared.PrettyPrint')(meta))
	local reply = {'meta', {result=true, meta=meta}}

	print(cjson.encode(reply))
	obj.server:send(cjson.encode(reply))
end

return mpft
