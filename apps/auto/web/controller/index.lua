local cjson = require 'cjson.safe'
local api = require "shared.api.iobus.client"
platform = require "shared.platform"
path_plat = platform.path.apps

return {
	get = function(req, res)
	
	local path_plat = path_plat .. "/" .. app.appname .. "/config/" .. app.appname .. "/"

	local excute = "mkdir " .. path_plat .. " -p"
	if not os.execute(excute) then
		res:write(app.appname)
		return
	end
	
	local filename = path_plat .. app.appname .. "_config.json"
--	res:write(app.appname)
	
	local file, err = io.open(filename, "a+")
	if not file then
		res:write(err)
		return
	end
	local config = file:read("*a");
	if config == "" then
--		res:write("@@@@@@@@@@@@@@@@@@@@")
		config = '[]'
	end
		config = cjson.decode(config)
	file:close();	
	len = 0
	while true do
		index,value = next(config,index)
		if index then
			len = index
		else
			break
		end
	end
--	res:write(len)
	--local api = require "shared.api.iobus.client"
	local client = api.new('web')

--		res:write(config[2].config.input)
		local i =0
		len = tonumber(len)
	while i < len do
		if tostring(config[len-i].config.input) ~= "0" then
			local r, err = client:read(config[len-i].config.input)
			if r then
				config[len-i].config.input = r.value
			else
			end
		else
			config[len-i].tree.name=""
			config[len-i].config.input=""
		end
		i = i+1
	end
		
		config = cjson.encode(config)
		res:ltp('index.html', {lwf = lwf, app = app,json_text = config})
		collectgarbage('collect')
	end,

	post = function(req, res)

	local path_plat = path_plat .. "/" .. app.appname .. "/config/" .. app.appname .. "/"
	local filename = path_plat .. app.appname .. "_config.json"
--	res:write(app.appname)
	
	local file, err = io.open(filename, "a+")
	if not file then
		res:write(err)
		return
	end
	local config = file:read("*a");
	config = cjson.decode(config)
		
	file:close();	
	len = 0
	while true do
		index,value = next(config,index)
		if index then
			len = index
		else
			break
		end
	end
--	res:write(len)

	local client = api.new('web')

--		res:write(config[2].config.input)
		local i =0
		len = tonumber(len)
	while i < len do
		if tostring(config[len-i].config.input) ~= "0" then
			local r, err = client:read(config[len-i].config.input)
			if r then
				config[len-i].config.input = r.value
			else
			end
		else
	--		config[len-i].config.input = "x"
			config[len-i].tree.name=""
			config[len-i].config.input=""
		end
		i = i+1
	end
		
		config = cjson.encode(config)
		res:write(config)
	end
}














