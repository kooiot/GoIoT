local pdu = require 'modbus.pdu'
local log = require 'shared.log'
local unpack = table.unpack or unpack

local class = {}

local function packet_check(adu)
	return function(msg)
		return adu.check(msg)
	end
end

function class:request (unit, name, ...) 
	local args = {...}

	local p, parser = pdu[name](unpack(args))
	self.transcode = self.transcode + 1
	local _, adu_raw = self.adu.encode(p, self.transcode, unit)

	self.requests[self.transcode] = adu_raw

	--- write to pipe
	-- fiber.await(self.internal.write(adu_raw))
	self.stream.send(adu_raw)

	--local raw = fiber.await(self.internal.read())
	local raw = self.stream.read(packet_check(self.adu), 500)
	if not raw then
		return nil, 'Packet timeout'
	end

	local trans, unit, pdu_raw = self.adu.decode(raw)
	local pdu, err = pdu.parser_pdu(pdu_raw)
	if not pdu then
		return nil, err
	end

	local _, err = parser(pdu)
	if _ ~= pdu then
		--log:error('MODBUS', 'P: '..err)
		return nil, err
	end
	return pdu, err
--[[
	for k, v in pairs(p:data()) do
	print(k, v)
	end
]]--
end

return function (stream, adu)
	return setmetatable({stream = stream, adu = adu, requests = {}, transcode = 0, stop = false}, {__index=class})
end

