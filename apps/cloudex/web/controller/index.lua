local function doi(req, res, info)
	local config = require 'shared.api.config'

	assert(app.appname)
	local name = app.appname..'.conf'
	local conf = config.get(name) or {}
	conf.gzip = conf.gzip or false
	conf.key = conf.key or "6015c744795762df41e9ebfa25fd625c"
	conf.url = conf.url or 'http://172.30.1.121:8080/api/'
	conf.timeout = conf.timeout or 5

	res:ltp('index.html', {lwf=lwf, app=app, key = conf.key, url=conf.url, timeout=conf.timeout, gzip=conf.gzip, info=info})
end
return {
	get = 	doi,
	post = function(req, res)
		local name = app.appname..'.conf'
		local key = req:get_arg('key')
		local url = req:get_arg('url')
		local timeout = req:get_arg('timeout')
		local gzip = req:get_arg('gzip') and true or false
		local info = nil
		if key then
			local config = require 'shared.api.config'
			local r, err = config.set(name, {key=key, url=url, timeout=timeout, gzip=gzip and 'checked=true' or ''})
			if r then
				info = 'Key has been saved!!'
			else
				info = err
			end
		else
			info = 'Incorrect Post!!!'
		end
		doi(req, res, info)
	end
}
