local pp = require ('shared.PrettyPrint')
local log = require('shared.log')
local cjson = require('cjson.safe')

local function import_section(name, section)
	--[[
	print('import', "Import section "..name)
	for k, v in pairs(section) do
		if tonumber(v[1]) == 0 then
			for k, v in pairs(v) do
				print(k,v)
			end
		end
	end
	]]--

	if name == 'PORTS' then
	end

	if name == 'TAGS' then
		print(pp(section))
		file = io.open('tags.json', "w+")
		file:write(cjson.encode(section))
		file:close()
	end

	if name == 'SETTINGS' then
	end
end

local function import(app, filename)
	log:debug(app.name or 'example', "Import from file "..filename)

	if not filename:match("%.csv$") then
		return nil, "Only csv file can not imported to "..ioname
	end

	local csv = require 'shared.util.csv'
	local t, err = csv.file(filename)
	if not t then
		return nil, err or "failed to open the csv file"
	else
		--[[
		print(pp(t))
		]]--
		local section = {}
		local bsec = false
		local sec_name = ""
		for k, v in pairs(t) do
			if #v ~= 0 then
				if not bsec then
					if v[1] == "SECTION_BEGIN" and v[2] then
						sec_name = v[2]
						bsec = true
						section = {}
					end
				else
					if v[1] == 'SECTION_END' then
						bsec = false
						import_section(sec_name, section)
					else
						if tonumber(v[1]) ~= 0 then
							table.insert(section, v)
						end
					end
				end
			end
		end
		return true
	end
end


return {
	import = import
}
