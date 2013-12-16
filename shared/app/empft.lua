local mpft = {}

mpft['start'] = function(obj, msg)
	local r, status = obj.onStart()
end

mpft['stop'] = function(obj, msg)
	local r, status = obj.onStop()
end

mpft['reload'] = function(obj, msg)
	local r, status = obj.onReload()
end

return mpft
