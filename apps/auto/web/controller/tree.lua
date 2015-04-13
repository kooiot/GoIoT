cjson = require "cjson.safe"
url = require "socket.url"
platform = require "shared.platform"
bit32 = require 'shared.compat.bit'
path = platform.path.apps


return {
	get = function(req, res)
	
			res:ltp('tree.html', {lwf=lwf, app=app, json_text = config, name = req:get_arg("name"), ratios = ratios})
	end,

	post = function(req, res)

	end
}
