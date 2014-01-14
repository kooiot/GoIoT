local mpft = {}

mpft['pause'] = function(obj, event)
	local r, status = obj.on_pause()
end

mpft['close'] = function(obj, event)
	local r, status = obj.on_close()
end

mpft['reload'] = function(obj, event)
	local r, status = obj.on_reload()
end

mpft['info'] = function(obj, event)
	local r, status = obj.send_notice()
end

return mpft
