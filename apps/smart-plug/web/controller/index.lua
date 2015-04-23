local function list_devs(appname)
	assert(appname)
	local api = require 'shared.api.app'
	local port, err = api.find_app_port(appname)
	local devs = {}
	if port then
		local client = api.new(port)
		devs, err = client:request('list', {})
	end
	return devs, err
end

return {
	get = 	function(req, res)
		local devs, err = list_devs(app.appname)
		devs = devs or {}
		res:ltp('index.html', {lwf=lwf, app=app, devs=devs, info=err})
	end,
	post = function(req, res)
		local info = 'DONE'
		local action = req:get_arg('action')
		if action == 'command' then
			local command = req:get_arg('command')
			local name = req:get_arg('name')

			if command and string.len(command) ~= 0 and name and string.len(name) ~= 0 then
				local cjson = require 'cjson.safe'
				local iobus = require 'shared.api.iobus.client'
				local path = app.appname..'/'..name..'/commands/'..command
				local client = iobus.new('web')
				client:command(path, {from='web'})
			else
				info = "incorrect post"
			end
		elseif action =='state' then
			local name = req:get_arg('name')
			local devs, err = list_devs(app.appname)
			if devs then
				info = "Not found the device"
				for k, dev in pairs(devs) do
					if k == name then
						local cjson = require 'cjson.safe'
						res.headers['Content-Type'] = 'application/json'
						res:write(cjson.encode(dev))
						return
					end
				end
			else
				info = err
			end
		else
			info = "Incorrect action post"
		end
		res:write(info)
	end
}
