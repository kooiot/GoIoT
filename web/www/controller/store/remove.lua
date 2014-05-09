local lname = cgilua.POST.lname
local mode = cgilua.POST.mode
if lname then
	local r, err = cloud.remove(lname, mode)
	if r then
		put('DONE')
	else
		put('ERROR', err)
	end
else
	put('Error parameter')
end
