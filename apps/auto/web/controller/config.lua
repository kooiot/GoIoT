cjson = require "cjson.safe"
platform = require "shared.platform"
path = platform.path.apps

return {
	get = function(req, res)
		local path = path .. "/" .. app.appname .. "/config/" .. app.appname .. "/"
		local excute = "mkdir " .. path .. " -p"
		if not os.execute(excute) then
			res:write(app.appname)
			return
		end
		local filename = path .. app.appname .. "_config.json"
		local file, err = io.open(filename, "a+")
		if file then
			local config = file:read("*a")
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
			file:close()

			local api = require "shared.api.iobus.client"
			local client = api.new("web")

			local commands = {}
			local inputs = {}

			local nss, err = client:enum(".+")

			if nss then
				for ns, devs in pairs(nss) do
					local tree, err = client:tree(ns)
					if tree then
						for k, dev in pairs(tree.devices) do
							for k, v in pairs(dev.commands) do
								commands[#commands + 1] = {name = v.name, desc = v.desc, path = v.path}
							end
							for k, v in pairs(dev.inputs) do
								inputs[#inputs + 1] = {name = v.name, desc = v.desc, path = v.path}
							end
						end
					end
				end
			else
				info = err
			end

			res:ltp("config.html", {lwf=lwf, app=app, json_text = config, list=list, commands = commands, inputs = inputs})
		else
			res:write(err)
		end
	end,

	post = function(req, res)
		req:read_body()
		local path = path .. "/" .. app.appname .. "/config/" .. app.appname .. "/"
		local filename = path .. app.appname .. "_config.json"
		res:write(app.appname)
		local unit = req:get_post_arg("unit")
		local str = req:get_post_arg("str")
		local input = req:get_post_arg("input")
		local t = {}
		t.tree = {}
		local name = req:get_post_arg("name")
		local id = req:get_post_arg("id")
		local pId = req:get_post_arg("pId")
		local level = req:get_post_arg("level")
		t.tree.name = name
		t.tree.id = id
		t.tree.pId = pId
		t.tree.level = level
		t.config = {}
		t.config.unit = unit
		t.config.str = str
		t.config.input = input

		local file, err = io.open(filename, "a+")
		if not file then
			res:write(err)
			return
		end
		local json_text = file:read("*a")
		local tags = cjson.decode(json_text)
		local flags = false
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
