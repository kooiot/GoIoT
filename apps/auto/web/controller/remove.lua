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
		filename = path .. "/" .. app.appname .. "/config/" .. app.appname .. "/" .. filename .."_config.json"
		res:write(filename)
		local t = {}
		for k, v in pairs(config) do
			if v.tree.pId ~= id and v.tree.id ~= id then
				table.insert(t, v)
			end
		end
		file = io.open(filename, "w")
		t = cjson.encode(t)
		file:write(t)
		file:close()
	end
}
