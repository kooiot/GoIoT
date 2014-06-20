platform = require "shared.platform"
path = platform.path.apps
return {
	post = function(req, res)
		cjson = require "cjson.safe"
		req:read_body()
		local filename = req:get_post_arg("filename")
		local json_text = req:get_post_arg("json_text")
		local id = req:get_post_arg("id")
		local pId = req:get_post_arg("pId")
		local name = req:get_post_arg("name")
		config = cjson.decode(json_text)
		res:write(path)
		filename = path .. "/modbus/config/" .. app.appname .. "/" .. filename .."_config.json"
		res:write(filename)
		for k, v in pairs(config) do
			if v.tree.id == id and v.tree.pId == pId and v.tree.name == name then
				if tonumber(v.tree.pId) == 0 then
					file = io.open(filename, "w")
					config = ""
					file:write(config)
					file:close()
				else
					table.remove(config, k)
					file = io.open(filename, "w")
					config = cjson.encode(config)
					file:write(config)
					file:close()
				end
			end
		end
	end
}
