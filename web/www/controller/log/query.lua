return {
	get = function(req, res)
		local typ = req:get_arg('type', 'logs')

		local logs = app.model:get('logs')
		if not logs then
			res:write('')
		else
			res.headers['Content-Type'] = 'application/json'
			local logs, err = logs:query(typ)
			if logs then
				res:write(logs)
			else
				res:write(err)
			end
		end
		logs:close()
		collectgarbage('collect')
	end
}
