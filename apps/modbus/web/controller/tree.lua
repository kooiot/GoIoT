cjson = require "cjson.safe"
url = require "socket.url"
platform = require "shared.platform"
bit32 = require 'shared.compat.bit'
path = platform.path.apps

local function sortFunc(a, b)
	return #a < #b
end

local function combination(s)
	local t = {}
	local n = math.pow(2, #s) - 1
	for i = 1, n do
		local tmp = {}
		for j = 0, #s - 1 do
			if bit32.btest(i, bit32.lshift(1, j)) then
				tmp[#tmp + 1] = s[j + 1]
			end
		end
		t[#t + 1] = tmp
	end
	table.sort(t, sortFunc)
	return t
end

local function list(t)
	local t = t or {}
	local s = {}
	for i = 2, #t do
		s[#s + 1] = t[i].Name
	end
	return combination(s)
end

return {
	get = function(req, res)
		local filename = req:get_arg("name")
		if not filename then
			res:write('No file name specified')
			return
		end

		filename = path .. "/" .. app.appname .. "/config/" .. app.appname .. "/" .. filename .."_config.json"
		local file, err = io.open(filename, "a+")
		if file then
			ratios = {}
			local pfilename = path .. "/" .. app.appname .. "/config/" .. app.appname .. "/" .. app.appname .. "_config.json"
			local pfile, msg = io.open(pfilename, "a+")
			if pfile then
				pconfig = pfile:read("*a")
				pconfig = cjson.decode(pconfig)
				for k, v in pairs(pconfig) do
					if v.tree.name == req:get_arg("name") then
						id = v.tree.id
						pId = v.tree.pId
						ratios = v.config.ratio
						ratios = list(ratios)
					--	res:write(cjson.encode(ratios))
					end
				end
				pfile:close()
			else
				res:write(msg)
			end
			local config = file:read("*a")
			if config == "" then
				devices = {}
				t = {}
				t.tree = {}
				t.tree.id = id
				t.tree.pId = pId
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
				file:write(config)
			end
			file:close()
			res:ltp('tree.html', {lwf=lwf, app=app, json_text = config, name = req:get_arg("name"), ratios = ratios})
		else
			res:write(err)
		end
	end,

	post = function(req, res)
		req:read_body()
		local filename = req:get_post_arg("filename")
		filename = path .. "/" .. app.appname .. "/config/" .. app.appname .. "/" .. filename .."_config.json"
		local operation = req:get_post_arg("operation")
		local cycle = req:get_post_arg("cycle")
		if not cycle then
			res:write("error!")
		end
		local time_unit = req:get_post_arg("time_unit")
		local func = req:get_post_arg("func")
		local addr = req:get_post_arg("addr")
		local len = req:get_post_arg("len")
		local values = req:get_post_arg("values")
		--res:write(values)

		local t = {}
		t.tree = {}
		local name = req:get_post_arg("name")
		local id = req:get_post_arg("id")
		local pId = req:get_post_arg("pId")
		local checked = req:get_post_arg("checked")
		t.tree.name = name
		t.tree.id = id
		t.tree.pId = pId
		t.tree.checked = checked
		t.vals = {}
		t.request = {}
		t.request.operation = operation
		t.request.cycle = cycle
		t.request.time_unit = time_unit
		t.request.func = func
		t.request.addr = addr
		t.request.len = len

		local n = values:find("tblAppendGrid_rowOrder")
		local values = values:sub(0, n - 2)
		local tmp = {}
		local i = 1
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
			elseif i == 5 then
				tmp.Unit = v
				i = i + 1
			elseif i == 6 then
				tmp.Multiple = v
				i = i + 1
			elseif i == 7 then
				tmp.CTPT = v
				i = i + 1
			elseif i == 8 then
				tmp.Endianness = v
				i = i + 1
			else
				tmp.Calc = v
		--		a = tmp
				i = 1
				table.insert(t.vals, tmp)
				tmp = {}
			end

		end

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
