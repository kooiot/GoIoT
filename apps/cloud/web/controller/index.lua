local function doi(req, res, info)
	local config = require 'shared.api.config'
	local cjson = require 'cjson.safe'

	assert(app.appname)
	local name = app.appname..'.conf'
	local conf_json = config.get(name)
	local conf = cjson.decode(conf_json or "{}")
	conf.key = conf.key or "6015c744795762df41e9ebfa25fd625c"
	conf.url = conf.url or 'http://172.30.0.115:8000/RestService/'
	conf.timeout = conf.timeout or 5

	res:ltp('index.html', {lwf=lwf, app=app, key = conf.key, url=conf.url, timeout=conf.timeout, info=info})
end
return {
	get = 	doi,
	post = function(req, res)
		local name = app.appname..'.conf'
		local key = req:get_arg('key')
		local url = req:get_arg('url')
		local timeout = req:get_arg('timeout')
		local info = nil
		if key then
			local config = require 'shared.api.config'
			local cjson = require 'cjson.safe'
			local conf_str, err = cjson.encode({key=key, url=url, timeout=timeout})

			local r, err = config.set(name, conf_str)
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
