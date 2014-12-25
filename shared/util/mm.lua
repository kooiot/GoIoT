local function proc_mem_info()
	local f, err = io.popen('cat /proc/meminfo')
	if not f then
		return nil, err
	end
	local s = f:read('*a')
	print(s)
	f:close()
	local total = s:match("Total:%s-(%d+)")
	local free = s:match("Free:%s-(%d+)")

	print(total, free)
end


proc_mem_info()
