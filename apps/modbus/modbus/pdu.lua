encode = require "modbus.encode"
decode = require "modbus.decode"
local _M = {}



--Read Only
--0x01
_M.ReadCoilStatus = function(t)
	local fc = encode.int8(0x01)
	local hv, lv = encode.uint16(t.request.addr)
	local addr = hv .. lv
	hv, lv = encode.uint16(t.request.len)
	local len = hv .. lv
	local pdu = fc .. addr .. len
	return pdu
end

--0x02
_M.ReadInputStatus = function(t)
	local fc = encode.int8(0x02)
	local hv, lv = encode.uint16(t.request.addr)
	local addr = hv .. lv
	hv, lv = encode.uint16(t.request.len)
	local len = hv .. lv
	local pdu = fc .. addr .. len
	return pdu
end

--0x03
_M.ReadHoldingRegisters = function(t)
	local fc = encode.int8(0x03)
	local hv, lv = encode.uint16(t.request.addr)
	local addr = hv .. lv
	hv, lv = encode.uint16(t.request.len)
	local len = hv .. lv
	local pdu = fc .. addr .. len
	return pdu
end

--0x04
_M.ReadInputRegisters = function(t)
	local fc = encode.int8(0x04)
	local hv, lv = encode.uint16(t.request.addr)
	local addr = hv .. lv
	hv, lv = encode.uint16(t.request.len)
	local len = hv .. lv
	local pdu = fc .. addr .. len
	return pdu
end

--Write Only
--0x05
_M.ForceSingleCoil = function(t)
	local fc = encode.int8(0x05)

	local hv, lv = encode.uint16(t.request.addr)
	local addr = hv .. lv
	local pdu = fc .. addr

	for k,v in pairs(t.vals) do
		local data = tonumber(v.Data)
		local calc = v.Calc
		local func = require('shared.compat.env').load(calc, nil, nil, {data = data, encode = encode})
		data = func()
		pdu = pdu .. data
	end
	return pdu
end

--0x06
_M.PresetSingleRegister = function(t)
	local fc = encode.int8(0x06)
	local hv, lv = encode.uint16(t.request.addr)
	local addr = hv .. lv
	local pdu = fc .. addr

	for k,v in pairs(t.vals) do
		local data = tonumber(v.Data)
		local calc = v.Calc
		local func = require('shared.compat.env').load(calc, nil, nil, {data = data, encode = encode})
		data = func()
		pdu = pdu .. data
	end
	return pdu
end

--0x0F
_M.ForceMultipleCoils = function(t)
	local fc = encode.int8(0x0F)
	local hv, lv = encode.uint16(t.request.addr)
	local addr = hv .. lv
	hv, lv = encode.uint16(t.request.len)
	local len = hv .. lv
	local bytes = tonumber(t.request.len)
	if bytes % 8 ~= 0 then
		bytes = math.floor(bytes / 8) + 1
	else
		bytes = bytes / 8
	end
	local pdu = fc .. addr .. len .. encode.uint8(bytes)

	for k,v in pairs(t.vals) do
		local data = tonumber(v.Data)
		local calc = v.Calc
		local func = require('shared.compat.env').load(calc, nil, nil, {data = data, encode = encode})
		data = func()
		pdu = pdu .. data
	end
	return pdu
end

--0x10
_M.PresetMultipleRegs = function(t)
	local fc = encode.int8(0x10)
	local hv, lv = encode.uint16(t.request.addr)
	local addr = hv .. lv
	hv, lv = encode.uint16(t.request.len)
	local len = hv .. lv
	local bytes = tonumber(t.request.len) * 2
	local pdu = fc .. addr .. len .. encode.uint8(bytes)

	for k,v in pairs(t.vals) do
		local data = tonumber(v.Data)
		local calc = v.Calc
		local func = require('shared.compat.env').load(calc, nil, nil, {data = data, encode = encode})
		data = func()
		pdu = pdu .. data
	end
	return pdu
end

return _M
