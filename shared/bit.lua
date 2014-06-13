--- The wrapper for bit operation for lua5.2 and lua5.1/luajit with bitop

--- return bit32 if it already has in global
if bit32 then
	return bit32
else
	-- lua5.1 or luajit
	return require 'bit'
end
