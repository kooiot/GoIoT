--[[
	ParserCSVLine:http://lua-users.org/wiki/LuaCsv
]]-- 

--- CSV parser module
-- csv parsing helper
-- @module shared.csv
-- @author Dirk Chang
--
local _M = {}

--- Parse CSV Line function
-- It is copied from: http://lua-users.org/wiki/LuaCsv
-- @tparam string line one csv string line
-- @tparam string sep the csv seperator
-- @treturn table the csv content for line
local function ParseCSVLine (line,sep) 
	local res = {}
	local pos = 1
	sep = sep or ','
	while true do 
		local c = string.sub(line,pos,pos)
		if (c == "") then break end
		if (c == '"') then
			-- quoted value (ignore separator within)
			local txt = ""
			repeat
				local startp,endp = string.find(line,'^%b""',pos)
				txt = txt..string.sub(line,startp+1,endp-1)
				pos = endp + 1
				c = string.sub(line,pos,pos) 
				if (c == '"') then txt = txt..'"' end 
				-- check first char AFTER quoted string, if it is another
				-- quoted string without separator, then append it
				-- this is the way to "escape" the quote char in a quote. example:
				--   value1,"blub""blip""boing",value3  will result in blub"blip"boing  for the middle
			until (c ~= '"')
			table.insert(res,txt)
			assert(c == sep or c == "")
			pos = pos + 1
		else	
			-- no quotes used, just look for the first separator
			local startp,endp = string.find(line,sep,pos)
			if (startp) then 
				table.insert(res,string.sub(line,pos,startp-1))
				pos = endp + 1
			else
				-- no separator found -> use rest of string and terminate
				table.insert(res,string.sub(line,pos))
				break
			end 
		end
	end
	return res
end

--- read csv content from file
-- @tparam string path the cvs file path
-- @treturn table the parsed csv table object
_M.file = function(path)
	local file, err = io.open(path)
	if not file then
		return nil, err
	end

	local res = {}

	local line = file:read('*l')
	repeat
		table.insert(res, ParseCSVLine(line))
		line = file:read('*l')
	until line == nil

	file:close()

	return res
end

_M.buffer = function(buf)
	-- TODO:
end

return _M
