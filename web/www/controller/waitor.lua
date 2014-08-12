return {
	get = function(req, res)
		local name = req:get_arg('name')
		local link = req:get_arg('link', '/')
		if name then
			res:ltp('waitor.html', {lwf=lwf, app=app, service=name, link=link})
		else
			res:write('Incorrect arguments')
		end
	end
}
