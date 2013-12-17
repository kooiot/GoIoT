local mpft = {}

mpft['start'] = function(obj, event)
	local r, status = obj.onStart()
end

mpft['stop'] = function(obj, event)
	local r, status = obj.onStop()
end

mpft['reload'] = function(obj, event)
	local r, status = obj.onReload()
end

mpft['info'] = function(obj, event)
	local r, status = obj.sendNotice()
end

return mpft
