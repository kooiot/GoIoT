return {
	get = function(req, res)
		local config = require 'shared.api.config'
		local appname = app.appname
		local mod = config.get(appname..'.mod') or
		[[send*#!13001143649*#!你好！测试通过。
		]]
		res:write(mod)
	end,
	post = function(req, res)
		local mod_num = req:get_arg('user_mod_num')
		local mod_mes = req:get_arg('user_mod_mes')
		local mod = "send*#!" .. mod_num .. "*#!" ..mod_mes
		if not mod then
			res:write('mod string empty')
		else
			local config = require 'shared.api.config'
			local appname = app.appname
			local r, err = config.set(appname..'.mod', mod)
			if not r then
				res:write(err)
			else
				res:write('The message has send out')
			end
		end
	end
}
