local mon = require 'shared.api.mon'
local app_status = mon.query()

local app = cgilua.QUERY.app

local runned = {}
if not app_status or not app_status.result then
	cgilua.print('API failure!!!')
else
	for k,v in pairs(app_status.status) do
		if not app or app == k then
			runned[k] = true
			put([[
			<p>
			<label> Application: <b> ]]..k..[[ </b> </label>
			]])
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
			<input type="button" value="Start Debug" onClick="debugApp(']]..k..[[')">
			<input type="button" value="Reload" onClick="operateApp('reload', ']]..k..[[')">
			<input type="button" value="Close" onClick="operateApp('close', ']]..k..[[')">
			<a href="]]..url('apps/'..k..'/web', {name=k, port=v.port})..[["> Manage </a>
			</p>
			]])
		end
	end
end

if not app then
	local list = require 'shared.app.list'
	for k, v in pairs(list.list()) do
		for k, lname in pairs(v.insts) do
			if not runned[lname] then
				put([[
				<p>
				<label> Application: <b> ]]..lname..[[ </b> </label>
				]])
				put('<br/>')
				put('Description:'..v.app.desc)
				put('<br/>')
				put([[
				<input type="button" value="Start" onClick="operateApp('start', ']]..lname..[[')">
				<input type="button" value="Start Debug" onClick="debugApp(']]..lname..[[')">
				</p>
				]])
			end
		end
	end
end
