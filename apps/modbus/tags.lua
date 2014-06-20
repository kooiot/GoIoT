local cjson = require "cjson"
local ztimer = require "lzmq.timer"

return {
	load_tags = function(ioname)
		filename = "config/" .. ioname .. "/" .. ioname .. "_config.json"
		local file, msg = io.open(filename, "r")
		if file then
			json_text = file:read("*a")
			modbus  = cjson.decode(json_text)
			packets = {}
			ip_port = {}
			for k, v in pairs(modbus) do
				config = {}
				config.port_config = {}
				config.tags = {}
				if v.tree.pId ~= "0" then
					dname = "config/"  .. ioname .. "/" .. v.tree.name .. "_config.json"
					dfile, msg = io.open(dname, "r")
					if dfile then
						djson = dfile:read("*a")
						tags = cjson.decode(djson)
					else
						print(msg)
						dfile:close()
						return dfile
					end
					config.port_config = v.config
					config.tags = tags
					table.insert(packets, config)
				else
					ip_port = v.config
				end
			end
			for k, v in pairs(packets) do
				for k, v in pairs(v.tags) do
				if v.request.cycle then
					v.request.timer = ztimer.monotonic(v.request.cycle)
					v.request.timer:start()
				end
			end
			end
			return packets, ip_port
		else
			print(msg)
			file:close()
			return file
		end
	end
}
