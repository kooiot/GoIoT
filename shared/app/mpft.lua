local cjson = require 'cjson.safe'

local mpft = {}

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
	local r, status = obj.on_status()
	if not r then
		status = 'running'
	end
	local reply = { 'status', {result=true, status = status}}
	obj.server:send(cjson.encode(reply))
end

mpft['start'] = function(obj, vars)
	local r, status = obj.on_start()
	local reply = { 'start', {result=r, status = status}}
	obj.server:send(cjson.encode(reply))
end

mpft['stop'] = function(obj, vars)
	local r, status = obj.on_stop()
	local reply = { 'stop', {result=r, status = status}}
	obj.server:send(cjson.encode(reply))
end

mpft['reload'] = function(obj, vars)
	local r, status = obj.on_reload()
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
