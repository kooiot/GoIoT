--- Helper functions for getting system information
-- @author Dirk Chang
--

local _M = {}

--- Get the cpu model
-- @treturn string CPU Model 
_M.cpu_model = function()
	local f = io.popen('cat /proc/cpuinfo')
	local s = f:read('*all')
	f:close()
	--return s:match("Hardware%s+:%s+([^%c]+)")
	return s:match("name%s+:%s+([^%c]+)")
end

--- Get the output for uname
-- @tparam string arg The args for uname command. e.g. -a -A -u
-- @treturn string the output from uname
_M.uname = function(arg)
	local cmd = 'uname '..arg
	local f = io.popen(cmd)
	local s = f:read('*all')
	return s
end

--- Get the memory information
-- includes 'total' 'used' 'free'
-- @treturn table information struct {total=xx, used=xx, free=xx}
_M.meminfo = function()
	local f = io.popen('free')
	local s = f:read('*all')
	local info = s:gmatch("Mem:%s-(%d+)%s-(%d+)%s-(%d+)")
	local total, used, free = info()
	return {
		total = total,
		used = used,
		free = free
	}
end

--- Get he loadavg
-- output the loadavg as one table, includes: lavg_1, lavg_5, lavg_15, nr_running, nr_threads, last_pid
-- @treturn table Refer to description
_M.loadavg = function()
   local f = io.popen('cat /proc/loadavg')
   local s = f:read('*all')

   -- Find the idle times in the stdout output
   local tokens = s:gmatch('%s-([%d%.]+)')

   local avgs = {}
   for w in tokens do
	   avgs[#avgs + 1] = w
   end
   local lavg_1, lavg_5, lavg_15, nr_running, nr_threads, last_pid = table.unpack(avgs)
   return {
		lavg_1 = lavg_1,
		lavg_5 = lavg_5,
		lavg_15 = lavg_15,
		nr_running = nr_running,
		nr_threads = nr_threads,
		last_pid = last_pid
   }
end

--- Get the network information
-- @tparam string ifname The interface name
-- @treturn table
local function network_if(ifname)
	local f = io.popen('LANG=C ifconfig '..ifname)
	local s = f:read('*all')
	local hwaddr = s:match('HWaddr%s-(%g+)')
	local ipv4 = s:match('inet%s+addr:%s-(%g+)')
	local ipv6 = s:match('inet6%s+addr:%s-(%g+)')
	return {hwaddr=hwaddr, ipv4 = ipv4, ipv6=ipv6}
end

--- List all network interfaces
-- @treturn table Includes all network information
_M.network = function()
	local f = io.popen('cat /proc/net/dev')
	local s = f:read('*all')
	local tokens = s:gmatch('%s-([%g^:]+):')
	local ifs = {}
	for w in tokens do
		if w ~= 'lo' then
			ifs[#ifs + 1] = w
		end
	end
	local info = {}
	for k, v in pairs(ifs) do
		info[v] = network_if(v)
	end
	return info;
end

return _M