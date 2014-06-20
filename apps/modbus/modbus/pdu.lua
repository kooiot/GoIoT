encode = require "modbus.encode"
decode = require "modbus.decode"
local _M = {}



--Read Only
--0x01
_M.ReadCoilStatus = function(t)
	local fc = encode.int8(0x01)
	local addr = encode.uint16(t.request.addr, 3)
	local len = encode.uint16(t.request.len, 3)
	local pdu = fc .. addr .. len
	return pdu
end

--0x02
_M.ReadInputStatus = function(t)
	local fc = encode.int8(0x02)
	local addr = encode.uint16(t.request.addr, 3)
	local len = encode.uint16(t.request.len, 3)
	local pdu = fc .. addr .. len
	return pdu
end

--0x03
_M.ReadHoldingRegisters = function(t)
	local fc = encode.int8(0x03)
	local addr = encode.uint16(t.request.addr, 3)
	local len = encode.uint16(t.request.len, 3)
	local pdu = fc .. addr .. len
	return pdu
end

--0x04
_M.ReadInputRegisters = function(t)
	local fc = encode.int8(0x04)
	local addr = encode.uint16(t.request.addr, 3)
	local len = encode.uint16(t.request.len, 3)
	local pdu = fc .. addr .. len
	return pdu
end

--Write Only
--0x05
_M.ForceSingleCoil = function(t)
	local fc = encode.int8(0x05)

	local addr = encode.uint16(t.request.addr, 3)
	local pdu = fc .. addr

	for k,v in pairs(t.vals) do
		for k, v in pairs(v) do
			if k == "Address" then
				data_addr = tonumber(v)
			end
			if k == "Endianness" then
				option = tonumber(v)
			end
			if k == "Data" then
				data = tonumber(v)
			end
		end
		if option == 1 or option == 2 then
			pdu = pdu .. encode.uint8(data)
		elseif option == 3 then
			pdu = pdu .. encode.uint16(data, 3)
		elseif option == 4 then
			pdu = pdu .. encode.uint16(data, 4)
		elseif option == 5 then
			pdu = pdu .. encode.uint32(data, 5)
		elseif option == 6 then
			pdu = pdu .. encode.uint32(data, 6)
		elseif option == 7 then
			pdu = pdu .. encode.uint32(data, 7)
		elseif option == 8 then
			pdu = pdu .. encode.uint32(data, 8)
		end
	end
	return pdu
end

--0x06
_M.PresetSingleRegister = function(t)
	local fc = encode.int8(0x06)
	local addr = encode.uint16(t.request.addr, 3)
	local pdu = fc .. addr

	for k,v in pairs(t.vals) do
		for k, v in pairs(v) do
			if k == "Address" then
				data_len = tonumber(v)
			end
			if k == "Endianness" then
				option = tonumber(v)
			end
			if k == "Data" then
				data = tonumber(v)
			end
		end
		if option == 1 or option == 2 then
			pdu = pdu .. encode.uint8(data)
		elseif option == 3 then
			pdu = pdu .. encode.uint16(data, 3)
		elseif option == 4 then
			pdu = pdu .. encode.uint16(data, 4)
		elseif option == 5 then
			pdu = pdu .. encode.uint32(data, 5)
		elseif option == 6 then
			pdu = pdu .. encode.uint32(data, 6)
		elseif option == 7 then
			pdu = pdu .. encode.uint32(data, 7)
		elseif option == 8 then
			pdu = pdu .. encode.uint32(data, 8)
		end
		--[[
		if length == 2 then
			if option == 1 then
				pdu = pdu .. encode.uint16(data, 1)
			else
				pdu = pdu .. encode.uint16(data, 2)
			end
		elseif length == 4 then
			if option == 1 then
				pdu = pdu .. encode.uint32(data, 1)
			elseif option == 2 then
				pdu = pdu .. encode.uint32(data, 2)
			elseif option == 3 then
				pdu = pdu .. encode.uint32(data, 3)
			elseif option == 4 then
				pdu = pdu .. encode.uint32(data, 4)
			end
		else
			pdu = pdu .. encode.uint8(data)
		end
		--]]
	end
	return pdu
end

--0x0F
_M.ForceMultipleCoils = function(t)
	local fc = encode.int8(0x0F)
	local addr = encode.uint16(t.request.addr, 3)
	local len = encode.uint16(t.request.len, 3)
	local bytes = tonumber(t.request.len)
	if bytes % 8 ~= 0 then
		bytes = math.floor(bytes / 8) + 1
	else
		bytes = bytes / 8
	end
	local pdu = fc .. addr .. len .. encode.uint8(bytes)

	for k,v in pairs(t.vals) do
		for k, v in pairs(v) do
			if k == "Address" then
				data_len = tonumber(v)
			end
			if k == "Endianness" then
				option = tonumber(v)
			end
			if k == "Data" then
				data = tonumber(v)
			end
		end
		if option == 1 or option == 2 then
			pdu = pdu .. encode.uint8(data)
		elseif option == 3 then
			pdu = pdu .. encode.uint16(data, 3)
		elseif option == 4 then
			pdu = pdu .. encode.uint16(data, 4)
		elseif option == 5 then
			pdu = pdu .. encode.uint32(data, 5)
		elseif option == 6 then
			pdu = pdu .. encode.uint32(data, 6)
		elseif option == 7 then
			pdu = pdu .. encode.uint32(data, 7)
		elseif option == 8 then
			pdu = pdu .. encode.uint32(data, 8)
		end
		--[[
		if length == 2 then
			if option == 1 then
				pdu = pdu .. encode.uint16(data, 1)
			else
				pdu = pdu .. encode.uint16(data, 2)
			end
		elseif length == 4 then
			if option == 1 then
				pdu = pdu .. encode.uint32(data, 1)
			elseif option == 2 then
				pdu = pdu .. encode.uint32(data, 2)
			elseif option == 3 then
				pdu = pdu .. encode.uint32(data, 3)
			elseif option == 4 then
				pdu = pdu .. encode.uint32(data, 4)
			end
		else
			pdu = pdu .. encode.uint8(data)
		end
		--]]
	end
	return pdu
end

--0x10
_M.PresetMultipleRegs = function(t)
	local fc = encode.int8(0x10)
	local addr = encode.uint16(t.request.addr, 3)
	local len = encode.uint16(t.request.len, 3)
	local bytes = tonumber(t.request.len) * 2
	local pdu = fc .. addr .. len .. encode.uint8(bytes)

	for k,v in pairs(t.vals) do
		for k, v in pairs(v) do
			if k == "Address" then
				length = tonumber(v)
			end
			if k == "Endianness" then
				option = tonumber(v)
			end
			if k == "Data" then
				data = tonumber(v)
			end
		end
		if option == 1 or option == 2 then
			pdu = pdu .. encode.uint8(data)
		elseif option == 3 then
			pdu = pdu .. encode.uint16(data, 3)
		elseif option == 4 then
			pdu = pdu .. encode.uint16(data, 4)
		elseif option == 5 then
			pdu = pdu .. encode.uint32(data, 5)
		elseif option == 6 then
			pdu = pdu .. encode.uint32(data, 6)
		elseif option == 7 then
			pdu = pdu .. encode.uint32(data, 7)
		elseif option == 8 then
			pdu = pdu .. encode.uint32(data, 8)
		end
		--[[
		if length == 2 then
			if option == 1 then
				pdu = pdu .. encode.uint16(data, 1)
			else
				pdu = pdu .. encode.uint16(data, 2)
			end
		elseif length == 4 then
			if option == 1 then
				pdu = pdu .. encode.uint32(data, 1)
			elseif option == 2 then
				pdu = pdu .. encode.uint32(data, 2)
			elseif option == 3 then
				pdu = pdu .. encode.uint32(data, 3)
			elseif option == 4 then
				pdu = pdu .. encode.uint32(data, 4)
			end
		else
			pdu = pdu .. encode.uint8(data)
		end
		--]]
	end
	return pdu
end

return _M
