cjson = require "cjson.safe"
platform = require "shared.platform"
path = platform.path.apps

return {
	get = function(req, res)
		local filename = path .. "/" .. app.appname .. "/config/" .. app.appname .. "/" .. app.appname .. "_config.json"
		local file, msg = io.open(filename, "r")
		if file then
			devices = file:read("*a")
			devices = cjson.decode(devices)
			if #devices <= 1 then
				res:write("Can not found device")
				return
			end
			default_tree = {}
			for k, v in pairs(devices) do
				if v.tree.pId ~= "0" then
					local dname = path .. "/" .. app.appname .. "/config/" .. app.appname .. "/" .. v.tree.name .. "_config.json"
					dfile, msg = io.open(dname, "r")
					dev_name = v.tree.name
					if dfile then
						djson = dfile:read("*a")
						tags = cjson.decode(djson)
						for k, v in pairs(tags) do
							if k ~= 1 then
								v.tree.name = dev_name .. "_" .. v.tree.name
								default_tree[#default_tree + 1] = v.tree
							end
						end
					else
						print(msg)
						dfile:close()
						return dfile
					end 
				end 
			end 
			default_tree = cjson.encode(default_tree)
			file:close()
		else
			res:write(msg)
		end

		local orderfile = path .. "/" .. app.appname .. "/config/" .. app.appname .. "/" .. "order.json"
		local order, err = io.open(orderfile, "r")
		if order then
			tree = order:read("*a")
			order:close()
		else
			tree = default_tree
		end
		res:ltp('packet_sequencing.html', {lwf=lwf, app=app, json_text=tree, default_tree=default_tree})
	end,

	post = function(req, res)
		req:read_body()
		local nodes = req:get_post_arg("nodes")
		nodes = cjson.decode(nodes)
		local tree = {}
		for k, v in pairs(nodes) do
			local tag = {}
			tag.id = v.id
			tag.name = v.name
			tag.checked = v.checked
			tree[#tree + 1] = tag
		end
		local filename = path .. "/" .. app.appname .. "/config/" .. app.appname .. "/" .. "order.json"
		local file = io.open(filename, "w")
		file:write(cjson.encode(tree))
		file:close()
	end
}


