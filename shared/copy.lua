
local function deepcopy (orig)
	local orig_type = type(orig)
	local copy
	if orig_type == 'table' then
		copy = {}
		for orig_key, orig_value in next, orig, nil do
			copy[deepcopy(orig_key)] = deepcopy(orig_value)
		end
		setmetatable(copy, deepcopy(getmetatable(orig)))
	else -- number, string, boolean, etc
		copy = orig
	end
	return copy
end

local function inplacecopy(from, to)
	if type(from) == 'table' then
		for k, v in pairs(to) do
			to[k] = nil
		end

		for k, v in pairs(from) do
			to[k] = v
		end
	else
		to = from 
	end
end

return {
	deep = deepcopy,
	inplace = inplacecopy,
}
