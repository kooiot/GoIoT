local cjson = require "cjson"
local ztimer = require "lzmq.timer"

local function order(ioname, packets)
	local filename = "config/" .. ioname .. "/" .. "order.json"
	local file, msg = io.open(filename, "r")
	local order_tags = {}
	if file then
		local tags = file:read("*a")
		tags = cjson.decode(tags)
		for k, v in pairs(tags) do
			if v.checked then
				config = {}
				local id = v.id
				local name = v.name
				for k, v in pairs(packets) do
					if string.match(name, k) then
						for k, v in pairs(v) do
							config.port_config = v.port_config
							for k, v in pairs(v.tags) do
								if id == v.tree.id then
									config.tags = v
								end
							end
						end
					end
				end
				order_tags[#order_tags + 1] = config
			end
		end
		file:close()
	else
		for k, v in pairs(packets) do
			for k, v in pairs(v) do
				local port_config = v.port_config
				for k, v in pairs(v.tags) do
					config = {}
					config.port_config = port_config
					config.tags = v
					order_tags[#order_tags + 1] = config
				end
			end
		end
	end
	--print(cjson.encode(order_tags))
	return order_tags
end

return {
	load_tags = function(ioname)
		filename = "config/" .. ioname .. "/" .. ioname .. "_config.json"
		local file, msg = io.open(filename, "r")
		if file then
			local devices = file:read("*a")
			devices = cjson.decode(devices)
			local packets = {}
			local modbus_mode = {}
			for k, v in pairs(devices) do
				config = {}
				config.port_config = {}
				config.tags = {}
				if v.tree.pId ~= "0" then
					packets[v.tree.name] = {}
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
					table.remove(tags, 1)
					packets[v.tree.name][#packets[v.tree.name] + 1] = config
				else
					modbus_mode = v.config
				end
			end
			packets = order(ioname, packets)

			for k, v in pairs(packets) do
				if v.tags.request.cycle then
					v.tags.request.timer = ztimer.monotonic(tonumber(v.tags.request.cycle))
					v.tags.request.timer:start()
				end
			end
			return packets, modbus_mode
		else
			print(msg)
			return nil
		end
	end
}

