return {
	get = function(req, res)
		local config = require 'shared.api.config'
		local appname = app.appname
		local mod = config.get(appname..'.mod') or
		[[send*#!13001143649*#!nihao
		]]
		res:ltp('edit.html', {lwf=lwf, app=app, commands=commands, signal=signal})
	end,
	post = function(req, res)
		local mod = req:get_arg("tblAppendGrid")
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
