local mon = require 'shared.api.mon'
local app_status = mon.query()

local app = cgilua.QUERY.app

if not app_status or not app_status.result then
	cgilua.print('API failure!!!')
else
	for k,v in pairs(app_status.status) do
		if not app or app == k then
			put([[
			<p>
			<label> Application: <b> ]]..k..[[ </b> </label>
			]])
			put('<br/>')
			put('Project:'..v.product)
			put('<br/>')
			put('Description:'..v.desc)
			put('<br/>')
			put('Running:', v.run and 'True' or 'False')
			put('<br/>')
			put('Port:', v.port or 'None')
			put('<br/>')
			put('Last Notice:', os.date("%c", v.last))
			put('<br/>')
			put([[
			<input type="button" value="Start" onClick="operateApp('start', ']]..k..[[')">
			<input type="button" value="Reload" onClick="operateApp('reload', ']]..k..[[')">
			<input type="button" value="Stop" onClick="operateApp('stop', ']]..k..[[')">
			<a href="]]..url('apps/'..v.product..'/web', {name=k, port=v.port})..[["> Manage </a>
			</p>
			]])
		end
	end
end

