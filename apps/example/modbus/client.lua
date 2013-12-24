local pdu = require 'modbus.pdu'

local class = {}

function class:request (unit, name, ...) 
	local args = {...}
	return function(callback)
		if self.stream and self.apdu then
			fiber.new( function(cb)
				local p, parser = pdu[name](unpack(args))
				self.transcode = self.transcode + 1
				local _, apdu_raw = self.apdu.encode(p, self.transcode, unit)

				self.requests[self.transcode] = apdu_raw

				--- write to pipe
				fiber.await(self.internal.write(apdu_raw))
				--			print(#self.requests)
				local raw = fiber.await(self.internal.read())
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
				cb(p)
			end, callback)()
		end
	end
end

return function (stream, apdu)
	return setmetatable({stream = stream, apdu = apdu, requests = {}, transcode = 0, stop = false}, {__index=class})
end

