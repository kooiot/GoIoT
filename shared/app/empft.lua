local mpft = {}

mpft['start'] = function(obj, event)
	local r, status = obj.on_start()
end

mpft['stop'] = function(obj, event)
	local r, status = obj.on_stop()
end

mpft['reload'] = function(obj, event)
	local r, status = obj.on_reload()
end

mpft['info'] = function(obj, event)
	local r, status = obj.send_notice()
end

return mpft
