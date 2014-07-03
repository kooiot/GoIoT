local cjson = require "cjson"
local ztimer = require "lzmq.timer"

return {
	load_tags = function(ioname)
		filename = "config/" .. ioname .. "/" .. ioname .. "_config.json"
		local file, msg = io.open(filename, "r")
		if file then
			json_text = file:read("*a")
			--print(json_text)
			modbus  = cjson.decode(json_text)
			packets = {}
			modbus_mode = {}
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
					modbus_mode = v.config
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
			return packets, modbus_mode
		else
			print(msg)
			return file
		end
	end
}

