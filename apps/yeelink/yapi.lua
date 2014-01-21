local api = require 'yapi.api'
local devices = require 'yapi.devices'
local sensors = require 'yapi.sensors'
local dp = require 'yapi.dp'

return {
	init = function(key)
		api.init(key)
	end,
	devices = devices,
	sensors = sensors,
	dp = dp,
}
