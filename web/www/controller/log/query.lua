return {
	get = function(req, res)
		local cjson = require 'cjson.safe'
		local typ = req:get_arg('type', 'logs')
		local clean = req:get_arg('clean')
		local limit = req:get_arg('limit')
		if limit then
			limit = tonumber(limit)
		end
		if type(clean) == 'string' then
			if clean == 'true' then
				clean = true
			else
				clean = false
			end
		end

		local logs = app.model:get('logs')
		if not logs then
			res:write('')
		else
			res.headers['Content-Type'] = 'application/json'
			local logs, err = logs:query(typ, clean)
			if logs then
				local src = req:get_arg('src')
				if src then
					local flogs = {}
					for k, v in pairs(logs) do
						local v = cjson.decode(v)
						if v and v.src == src then
							flogs[#flogs + 1] = v
						end
						if limit and #flogs > limit then
							table.remove(flogs, 1)
						end
					end
					logs = flogs
				end
				res:write(cjson.encode(logs))
			else
				res:write(err)
			end
		end
		logs:close()
		collectgarbage('collect')
	end
}
