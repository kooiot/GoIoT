debug("_path=", path)

local lp_file = true
if path:sub(-1) == '/' then
	path = path..'index.lp'
else
	if not path:match("%.lp$") then
		if path:match("%.lua$") then
			lp_file = false
		else
			path = path..'/index.lp'
		end
	end
end


-- Do not try to access the core/main.lua
if path == "main.lua" then
	path = "index.lp"
end

local file = io.open('core/'..path)

if file then
	file:close()
	if lp_file then
		--cgilua.htmlheader()
		-- load the pages now
		include("header.lp")
		include(path)
		include("footer.lp")
	else
		script(path)
	end
else
	include("header.lp")
	include('404.lp')
	include("footer.lp")
	--redirect('/404.html')
end
