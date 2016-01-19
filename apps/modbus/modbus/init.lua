
local _M = {}

_M.code = require 'modbus.code'
_M.pdu = require "modbus.pdu"
_M.adu = {
	tcp = require "modbus.adu.tcp"
}
_M.encode = require 'modbus.encode'
_M.decode = require 'modbus.decode'
_M.client = require 'modbus.client'

return _M
