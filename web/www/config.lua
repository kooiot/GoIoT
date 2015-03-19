--
-- This is a LWF Application Config file
-- 
--
local function get_sub_apps()
	return {
	}
end

local function get_auth_file()
	--[[
	local plat = require 'shared.platform'
	return plat.path.core..'/auth.key'
	]]--
	return '/tmp/core/auth.db'
end

return {
	static = 'static',
	session={
		key			= 'lwfsession', -- default is lwfsession
		pass_salt   = '8C7f8lProgw3U4IvVyDqk38bD0HAD8hBBfHZRMRF',
		salt		= 'tdzd77zTw3aHW8IqZgQteXUG3s5kFMQZQf2ODSXZ',
	},
	i18n = true,

	auth = 'simple',
	auth_file = get_auth_file(),

	debug={
		on = true,
		to = "response", -- "logger"
	},

	subapps = get_sub_apps()
}
