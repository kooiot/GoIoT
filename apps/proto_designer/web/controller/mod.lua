return {
	get = function(req, res)
		local config = require 'shared.api.config'
		local appname = app.appname
		local mod = config.get(appname..'.mod') or
		[[<a class="ui red button" onclick="send_command('GREE/关机');">关机</a>
<a class="ui teal button" onclick="send_command('GREE/开机');">开机</a>
<a class="ui red button" onclick="send_command('[&quot;DS/6&quot;, &quot;DS/0&quot;, &quot;DS/1&quot;]');">央视1高清</a>
]]
		res:write(mod)
	end,
	post = function(req, res)
		local mod = req:get_arg('user_mod')
		if not mod then
			res:write('mod string empty')
		else
			local config = require 'shared.api.config'
			local appname = app.appname
			local r, err = config.set(appname..'.mod', mod)
			if not r then
				res:write(err)
			else
				res:write('Mod string saved!')
			end
		end
	end
}
