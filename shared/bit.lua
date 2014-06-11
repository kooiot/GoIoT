if bit32 then
	return bit32
else
	-- lua5.1 or luajit
	return require 'bit'
end
