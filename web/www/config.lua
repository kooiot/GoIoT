--
-- This is a LWF Application Config file
-- 
--
local function get_sub_apps()
	--[[
	local f = io.open('/tmp/apps/_list')
	assert(f)
	]]--
	return {}
--[[
	return {
		demo3 = {path="/home/cch/kooweb/apps/subapp", config={}},
	}
	]]--
end

return {
	static = 'static',
	session={
		key			= 'lwfsession', -- default is lwfsession
		pass_salt   = '8C7f8lProgw3U4IvVyDqk38bD0HAD8hBBfHZRMRF',
		salt		= 'tdzd77zTw3aHW8IqZgQteXUG3s5kFMQZQf2ODSXZ',
	},

	auth = 'simple',

	debug={
		on = true,
		to = "response", -- "logger"
	},

	subapps = get_sub_apps()
}
