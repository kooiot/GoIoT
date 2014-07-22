local _M = {}

local CRC = function(adu)
	local crc;

	local function initCrc()
		crc = 0xffff;
	end
	local function updCrc(byte)
		crc = bit32.bxor(crc, byte);
		for i = 1, 8 do
			local j = bit32.band(crc, 1);
			crc = bit32.rshift(crc, 1);
			if j ~= 0 then
				crc = bit32.bxor(crc, 0xA001);
			end
		end
	end

	local function getCrc(adu)
		initCrc();
		for i = 1, #adu  do
			updCrc(adu:byte(i));
		end
		return crc;
	end
	return getCrc(adu);
end

local LRC = function(adu)
--[[	local uchLRC = 0
	for i, #adu do
		uchLRC = uchLRC + adu:byte(i)
	end
	-- return twos complement
--]]
	--TODO
end

_M.check = function(adu, checkmode) 
	local checknum = 0
	if checkmode == "1" then
		checknum = CRC(adu)
		hv, lv = encode.uint16(checknum)
		return lv .. hv
	end

	if checkmode == "2" then
		checknum = LRC(adu)
		hv, lv = encode.uint16(checknum)
		return hv .. lv
	end
end

return _M
