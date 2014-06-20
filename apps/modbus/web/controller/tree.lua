cjson = require "cjson.safe"
--config_path = "/opt/work/SymlinkV3/v3/core/apps/modbus/config/"
url = require "socket.url"
platform = require "shared.platform"
path = platform.path.apps

return {
	get = function(req, res)
		filename = req:get_arg("name")
		filename = path .. "/modbus/config/" .. filename .. "_config.json"
		local file = io.open(filename, "a+")
		if (file) then
			config = file:read("*a")
			if config == "" then
				devices = {}
				t = {}
				t.tree = {}
				t.tree.id = "1"
				t.tree.pId = "0"
				t.tree.name = req:get_arg("name")
				t.tree.isParent = true
				t.request = {}
				t.request.cycle = ""
				t.request.time_unit = ""
				t.request.func = ""
				t.request.addr = ""
				t.request.len = ""
				table.insert(devices, t)
				config = cjson.encode(devices)
				config = cjson.encode(devices)
				file:write(config)
			end
		end
		file:close()
		res:ltp('tree.html', {json_text = config})
	end,

	post = function(req, res)
		req:read_body()
		filename = req:get_post_arg("filename")
		filename = path .. "/modbus/config/" .. filename .. "_config.json"
		local cycle = req:get_post_arg("cycle")
		if not cycle then
			res:write("error!")
		end
		local time_unit = req:get_post_arg("time_unit")
		local func = req:get_post_arg("func")
		local addr = req:get_post_arg("addr")
		local len = req:get_post_arg("len")
		local values = req:get_post_arg("values")
	--	res:write(values)

		local t = {}
		t.tree = {}
		local name = req:get_post_arg("name")
		local id = req:get_post_arg("id")
		local pId = req:get_post_arg("pId")
		t.tree.name = name
		t.tree.id = id
		t.tree.pId = pId
		t.vals = {}
		t.request = {}
		t.request.cycle = cycle
		t.request.time_unit = time_unit
		t.request.func = func
		t.request.addr = addr
		t.request.len = len

		n = values:find("tblAppendGrid_rowOrder")
		values = values:sub(0, n - 2)
		tmp = {}
		i = 1
		--a = {}
		for k, v in values:gmatch("([^&=]+)=([^&=]+)") do
		--	res:write(v)
		--	a = {}
			v = v:gsub("+", " ")
			v = url.unescape(v)
			if i == 1 then
				tmp.Name = v
				i = i + 1
			elseif i == 2 then
				tmp.Description = v
				i = i + 1
			elseif i == 3 then
				tmp.Address = v
				i = i + 1
			elseif i == 4 then
				tmp.Data = v
				i = i + 1
			else
				tmp.Endianness = v
		--		a = tmp
				i = 1
				table.insert(t.vals, tmp)
				tmp = {}
			end

		end

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
			tags = {}
			local devices = {}
			devices = t
			table.insert(tags, t)
		end
		file:close()
		file = io.open(filename, "w")
		file:write(cjson.encode(tags))
		file:close()
	end
}
