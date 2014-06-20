cjson = require "cjson.safe"
platform = require "shared.platform"
path = platform.path.apps

return {
	get = function(req, res)
		filename = path .. "/modbus/config/" .. app.appname .."_config.json"
		local file = io.open(filename, "a+")
		if (file) then
			config = file:read("*a")
			if config == "" then
				devices = {}
				t = {}
				t.tree = {}
				t.tree.id = "1"
				t.tree.pId = "0"
				t.tree.name = app.appname
				t.tree.isParent = true
				t.config = {}
				t.config.port = ""
				t.config.sIp = ""
				t.config.unit = ""
				table.insert(devices, t)
				config = cjson.encode(devices)
				file:write(config)
				--res:write(config)
			end
		end
		file:close()
		res:ltp("index.html", {json_text = config, app=app})
	end,

	post = function(req, res)
		req:read_body()
		filename = path .. "/modbus/config/" .. app.appname .."_config.json"
		local port = req:get_post_arg("port")
		local sIp = req:get_post_arg("sIp")
		local unit = req:get_post_arg("unit")
		local t = {}
		t.tree = {}
		local name = req:get_post_arg("name")
		local id = req:get_post_arg("id")
		local pId = req:get_post_arg("pId")
		t.tree.name = name
		t.tree.id = id
		t.tree.pId = pId
		t.config = {}
		t.config.port = port
		t.config.sIp = sIp
		t.config.unit = unit

		file = io.open(filename, "a+")
		json_text = file:read("*a")
		tags = cjson.decode(json_text)
		flags = false
		if tags then
			for k, v in pairs(tags) do
				if v.tree.id == t.tree.id and v.tree.pId == t.tree.pId then
			--		res:write(tags[k].tree.id)
					tags[k] = t
					flags = true
					break
				end
			end
			if flags == false then
				table.insert(tags, t)
			end
		else
			table.insert(tags, t)
		end
		file:close()
		file = io.open(filename, "w")
		file:write(cjson.encode(tags))
		file:close()
	end
}
