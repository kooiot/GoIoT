local cjson = require 'cjson.safe'

local mpft = {}

mpft['version'] = function(obj, msg)
	local reply = {
		'version',
		{
			version = obj.version,
			build = obj.build,
		}
	}
	obj.server:send(cjson.encode(reply))
end

mpft['status'] = function(obj, msg)
	local r, status = obj.onStatus()
	if not r then
		status = 'running'
	end
	local reply = { 'status', {result=true, status = status}}
	obj.server:send(cjson.encode(reply))
end

mpft['start'] = function(obj, msg)
	local r, status = obj.onStart()
	local reply = { 'start', {result=r, status = status}}
	obj.server:send(cjson.encode(reply))
end

mpft['stop'] = function(obj, msg)
	local r, status = obj.onStop()
	local reply = { 'stop', {result=r, status = status}}
	obj.server:send(cjson.encode(reply))
end

mpft['reload'] = function(obj, msg)
	local r, status = obj.onReload()
	local reply = { 'reload', {result=r, status = status}}
	obj.server:send(cjson.encode(reply))
end

-- Get the application meta information
mpft['meta'] = function(obj, msg)
	local meta = obj:meta()
	--print(require('shared.PrettyPrint')(meta))
	local reply = {'meta', {result=true, meta=meta}}

	print(cjson.encode(reply))
	obj.server:send(cjson.encode(reply))
end

return mpft
