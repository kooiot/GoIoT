local function learn(appname)
	local api = require 'shared.api.app'
	local port = api.find_app_port(appname)
	if not port then
		return nil, "Cannot find app port"
	end

	local client = api.new(port)
	local reply, err = client:request('learn', {})
	if reply then
		return true
	end
	return nil, err
end

local function get_learn(appname)
	local api = require 'shared.api.app'
	local port = api.find_app_port(appname)
	if not port then
		return nil, "Cannot find app port"
	end

	local client = api.new(port)
	local reply, err = client:request('learn_result', {})
	if reply then
		return reply.learn
	end
	return nil, err
end

return {
	get = function(req, res)
		local r, err = learn(app.appname)
		local info = r and 'Ready to receive signal!!!' or err
		res:ltp('learn.html', {lwf=lwf, app=app, info=info})
	end,
	post = function(req, res)
		local action = req:get_arg('action')
		if action == 'result' then
			local r = get_learn(app.appname)
			res.headers['Content-Type'] = 'text/plain; charset=utf-8'
			if r then
				res:write(r)
			else
				res:write('')
			end
		elseif action == 'save' then
			res:write('Not implemented')
		end
	end,
}