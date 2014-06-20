local pdu = require 'modbus.pdu'
local log = require 'shared.log'
local cmd = require "modbus.code"

local class = {}

local function packet_check(apdu, port_config)
	return function(msg, t, port_config)
		return apdu.check(msg, t, port_config)
	end
end

local function hex_raw(raw)
	if not raw then
		return ""
	end 
	if (string.len(raw) > 1) then
		return string.format("%02X ", string.byte(raw:sub(1, 1)))..hex_raw(raw:sub(2))
	else
		return string.format("%02X ", string.byte(raw:sub(1, 1)))
	end 
end

function class:request (t, port_config) 
	p = pdu[cmd[tonumber(t.request.func)]](t)
	if not p then
		return nil
	end

	local _, apdu_raw = self.apdu.encode(p, t, port_config) --t.request.unit, t.request.checkmode)

	--- write to pipe
	-- fiber.await(self.internal.write(apdu_raw))
	self.stream.send(apdu_raw)

	--local raw = fiber.await(self.internal.read())
	local raw = self.stream.read(t, packet_check(self.apdu), 500)
	if not raw then
		return nil, 'Packet timeout'
	end

	local unit, pdu_raw = self.apdu.decode(raw)
	return pdu_raw, unit
	--[[local pdu, err = pdu.parser_pdu(pdu_raw)
	if not pdu then
		return nil, err
	end

	local _, err = parser(pdu)
	if _ ~= pdu then
		--log:error('MODBUS', 'P: '..err)
		return nil, err
	end
	return pdu, err
	]]--
--[[
	for k, v in pairs(p:data()) do
	print(k, v)
	end
]]--
end

return function (stream, apdu)
	return setmetatable({stream = stream, apdu = apdu, requests = {}, stop = false}, {__index=class})
end
