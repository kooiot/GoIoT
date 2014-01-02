local cjson = require 'cjson.safe'
local code = require 'modbus.code'

--[[
packets[1] = {
	code = 'ReadHoldingRegisters',
	unit = 1,
	start = 3,
	count = 16,
	names = {
		'data1',
		'data2',
		'data3',
		'data4',
		'data5',
		'data6',
		'data7',
		'data8',
		'data9',
		'data10',
		'data11',
		'data12',
		'data13',
		'data14',
		'data15',
		'data16',
	}
}

]]--


return {
	load_tags = function ()
		local res = {}

		local file = io.open('tags.json', 'r')
		local json_text = file:read("*a")
		local tags, err = cjson.decode(json_text)
		if not tags then
			return nil, err
		end
		packets = {}
		for k, v in pairs(tags) do
			local t = {}
			t.name = v[2]
			t.code = code[tonumber(v[3])]
			t.unit = tonumber(v[4])
			t.start = tonumber(v[5])
			t.count = tonumber(v[6])
			t.names = {}
			for c = 7, 64 do
				if not v[c] then
					break
				end
				table.insert(t.names, v[c])
			end
			print(t.name, t.code, t.unit, t.start, t.count, #t.names)
			if t.name and t.code and t.start and t.count and #t.names > 0 then
				table.insert(res, t)
			end
		end
		return res
	end
}
