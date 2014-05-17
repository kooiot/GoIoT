local cfg = {}

local function parse_section(lines)
	local cur = nil
	for _, v in pairs(lines) do
		--print(v)
		local sub, k1, k2, args = v:match('^(%G*)(%g+)%G+(%g+)%G*(%g*.*)$')
		--print('sub:'..sub, 'key', k1, k2, args)
		if string.len(sub) ~= 0 then
			if not cur then
				print('ERRRRRR')
			else
				cur[k1] = k2
			end
		else
			cfg[k1] = cfg[k1] or {}
			cfg[k1][k2] = {}
			cur = cfg[k1][k2]
			
			if args then
				for c in args:gmatch('%g+') do
					cur[#cur + 1] = c
				end
			end
		end
	end
end

local function parse_cfg(file)
	local lines = {}

	for c in file:lines() do

		if not c:match('%w+') then
			if #lines ~= 0 then
				parse_section(lines)
				lines = {}
			end
		else
			if not c:match('^%G*#') then
				lines[#lines + 1] = c
			end
		end
	end
	if #lines ~= 0 then
		parse_section(lines)
	end
end


local pp = require 'PrettyPrint'

local f, err = io.open('interfaces')
parse_cfg(f)
print(pp(cfg))
