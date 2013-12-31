local pdu = require 'modbus.pdu'
local log = require 'shared.log.client'

local class = {}

local function packet_check(apdu)
	return function(msg)
		return apdu.check(msg)
	end
end

function class:request (unit, name, ...) 
	local args = {...}

	local p, parser = pdu[name](table.unpack(args))
	self.transcode = self.transcode + 1
	local _, apdu_raw = self.apdu.encode(p, self.transcode, unit)

	self.requests[self.transcode] = apdu_raw

	--- write to pipe
	-- fiber.await(self.internal.write(apdu_raw))
	self.stream.send(apdu_raw)

	--local raw = fiber.await(self.internal.read())
	local raw = self.stream.read(packet_check(self.apdu), 500)
	if not raw then
		return nil, 'Packet timeout'
	end

	local trans, unit, pdu_raw = self.apdu.decode(raw)
	local pdu, err = pdu.parser_pdu(pdu_raw)
	if not pdu then
		return nil, err
	end

	local _, err = parser(pdu)
	if _ ~= pdu then
		log:error('P: '..err)
	end
	return pdu, err
--[[
	for k, v in pairs(p:data()) do
	print(k, v)
	end
]]--
end

return function (stream, apdu)
	return setmetatable({stream = stream, apdu = apdu, requests = {}, transcode = 0, stop = false}, {__index=class})
end

