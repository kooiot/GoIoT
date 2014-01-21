local ftp = require("socket.ftp")
local http = require("socket.http")
local url = require("socket.url")
local ltn12 = require("ltn12")

return function(src, dest)
	local u = url.parse(src, {path='/', scheme='ftp'})
	print('-----')
	for k,v in pairs(u) do
		print(k,v)
	end
	if not u.host then
		return nil, "Missing host : "..src
	end

	u.sink = ltn12.sink.file(io.open(dest, "wb"))

	if u.scheme == 'http' then
		local r, code, headers, status = http.request(u)
		if not r or code ~= 200 then
			return nil, status
		end
		return true
	end
	if u.scheme == 'ftp' then
		u.type = u.type or 'i'
		return ftp.get(u)
	end

	return nil, "Not support url type :"..u.scheme
end
