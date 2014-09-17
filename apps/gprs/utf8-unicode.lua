local str = ""
local function void (n) 
	local n1
	local num,b = math.modf(n/16)
	if num > 0 then
		void(num)
	end
	n1 = n%16
	if n1>=0 and n1<=9 then
		print (n1)
		str = str .. n1
	else
 		if 10 == n1 then 	
			print("A ")
			str = str .. "A"
		end
		if 11 == n1 then
			print("B ") 
			str = str .. "B"
		end
		if 12 == n1 then
			print("C ")
			str = str .. "C"
		end
		if 13 == n1 then
			print("D ") 
			str = str .. "D"
		end
		if 14 == n1 then
			print("E ") 
			str = str .. "E"
		end
		if 15 == n1 then
			print("F ") 
			str = str .. "F"
		end
	end
	return str
end 

function Utf8to32(utf8str)
    assert(type(utf8str) == "string")
    local res, seq, val = {}, 0, nil
    for i = 1, #utf8str do
        local c = string.byte(utf8str, i)
        if seq == 0 then
            table.insert(res, val)
            seq = c < 0x80 and 1 or c < 0xE0 and 2 or c < 0xF0 and 3 or
                  c < 0xF8 and 4 or --c < 0xFC and 5 or c < 0xFE and 6 or
                  error("invalid UTF-8 character sequence")
            val = bit32.band(c, 2^(8-seq) - 1)
        else
            val = bit32.bor(bit32.lshift(val, 6), bit32.band(c, 0x3F))
			val = tonumber(val)
        end
        seq = seq - 1
    end
    table.insert(res, val)
--    table.insert(res, 0)
    return res
end


local res={}
res = Utf8to32("工作愉快！")
i=0

for k, v in pairs (res) do
	local  str_1 = void(res[k])
	i = i+1
end

if i<8 then 
	i = i*2
	i = void(i)
	i='0' .. i
else
	i = i*2
	i = void(i)
end

print ("***************",string,"   ", i)

return str
