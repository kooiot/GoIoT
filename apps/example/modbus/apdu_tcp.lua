
local encode = require 'modbus.encode'
local decode = require 'modbus.decode'
local _M = {}

local function create_header(transaction, length, unit)
	local data = encode.uint16(transaction)..encode.uint16(0)..encode.uint16(length + 1)..encode.uint8(unit)
	return data
end

function _M.encode(pdu, transaction, unit)
	if not pdu then
		return nil, 'no pdu object'
	end
	local raw = pdu:raw()
	transaction = transaction or 1
	unit = unit or 1
	return true, create_header(transaction, string.len(raw), unit)..raw
end

function _M.decode(raw)
	local transaction = decode.uint16(raw:sub(1, 2))
	local _ = decode.uint16(raw:sub(3, 4))
	local len = decode.uint16(raw:sub(5, 6))
	local unit = decode.uint8(raw:sub(7, 7))
	return transaction, unit, raw:sub(8, 7 + len)
end

return _M
