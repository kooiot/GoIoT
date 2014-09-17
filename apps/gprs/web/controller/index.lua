	local function doi(req, res, info)
	assert (app.appname)
		info = "sfasdfsf"
		local cjson = require 'cjson.safe'
		local signal = 0
		local appapi = require 'shared.api.app'
		local port, err = appapi.find_app_port(app.appname)
		if not port then
			res:write(err or 'Error when trying to find application mgr port')
		else
			local client = appapi.new(port)
			local r, err = client:request('gprs_data', {})
				client:close()
			if r then
				signal = r.rules.signal
			end
		end
		
		rules = cjson.encode(rules)
		res:ltp('index.html', {lwf=lwf, app=app, commands=commands, signal=signal})

		end


return {
	get = 	doi,
	post = function(req, res)
		local cjson = require 'cjson.safe'

		local action = req:get_arg('action')
		if action == 'result' then

			local appapi = require 'shared.api.app'
			local port, err = appapi.find_app_port(app.appname)
			if not port then
				res:write(err or 'Error when trying to find application mgr port')
			else
				local client = appapi.new(port)
				local r, err = client:request('gprs_data', {})
				client:close()
				if r then
					--res:write('Done, you need restart the application mannually')
					signal = r.rules.signal
				else
					res:write(err..' '.. app.appname)
				end
			end
			res:write(signal)
		end 
		
		if action == 'gprs_state' then

			local appapi = require 'shared.api.app'
			local port, err = appapi.find_app_port(app.appname)
			if not port then
				res:write(err or 'Error when trying to find application mgr port')
			else
				local client = appapi.new(port)
				local r, err = client:request('gprs_data', {})
				client:close()
				if r then
					--res:write('Done, you need restart the application mannually')
					state = r.rules.state
				else
					res:write(err..' '.. app.appname)
				end
			end
			res:write(state)
		end 
	end
}

