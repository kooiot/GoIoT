local cjson = require "cjson"
local file = io.open("test_config.json")

local json_text = file:read("*a")

print(json_text)

local config = cjson.decode(json_text)

for k, v in pairs(config) do
	if tonumber(v.tree.level) == 1 then
		print(v.tree.id)
	end
end


