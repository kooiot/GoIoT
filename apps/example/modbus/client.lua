local pdu = require 'modbus.pdu'

local class = {}

local function packet_check(msg)
	return true, string.len(msg)
end

function class:request (port, unit, name, ...) 
	local args = {...}

	local p, parser = pdu[name](table.unpack(args))
	self.transcode = self.transcode + 1
	local _, apdu_raw = self.apdu.encode(p, self.transcode, unit)

	self.requests[self.transcode] = apdu_raw

	--- write to pipe
	-- fiber.await(self.internal.write(apdu_raw))
	port:send(apdu_raw)

	--local raw = fiber.await(self.internal.read())
	local raw = port:read(packet_check, 500)
	if not raw then
		print('no data ready')
		return
	end

	local trans, unit, pdu_raw = self.apdu.decode(raw)
	p = pdu.parser_pdu(pdu_raw)
	local _, err = parser(p)
	if _ ~= p then
		log:error('P: '..err)
	end

	--[[
	for k, v in pairs(p:data()) do
	print(k, v)
	end
	]]--

end

return function (apdu)
	return setmetatable({apdu = apdu, requests = {}, transcode = 0, stop = false}, {__index=class})
end

