--- System operation functions module
--
local download = require 'shared.util.download'
local platform = require 'shared.platform'
local delay_exec = require('shared.util.delay_exec')
local log = require 'shared.log'

local _M = {}

--- Get the current system version
-- @treturn string version string
_M.version = function()
	if _M.VERSION and _M.REVISION then
		return _M.VERSION, _M.REVISION
	end

	local f, err = io.open(platform.path.kooiot..'/version')
	if f then
		_M.VERSION = f:read('*l')
		_M.REVISION = f:read('*l')
		f:close()
	else
		_M.VERSION = '0'
		_M.REVISION = '0'
	end
	return _M.VERSION, _M.REVISION
end

--- Upgrade system
--@param file file is the filename or a table contains {name, content}
--@treturn boolean the result
--@treturn string the information readable
_M.upgrade = function(file)

	if file and type(file) == 'table' and next(file) then
		--- Name is ignored
		--local name = string.match(file.name, "([^:/\\]+)$")

		local tmp_file = platform.path.temp..'/core.sfs'
		local dest, err = io.open(tmp_file, "wb")
		if not dest then
			return nil, "Failed to save file, error:"..err
		end

		dest:write(file.contents)
		dest:close()

		local mv = 'mv '..tmp_file..' '..platform.path.core..'/core.sfs'
		local start = 'mount '..platform.path.core..'/core.sfs '..platform.path.kooiot
		local umount = 'umount '..platform.path.kooiot
		delay_exec('upgrade.sh', {'cd /', platform.path.kooiot..'/run.sh stop', umount, mv, 'sleep 3', start, platform.path.kooiot..'/run.sh start'})
	elseif type(file) == 'string' then
		local f, err = io.open(file)
		if not f then
			return nil, err
		end

		local mv = 'mv '..file..' '..platform.path.core..'/core.sfs'
		local start = 'mount '..platform.path.core..'/core.sfs '..platform.path.kooiot
		local umount = 'umount '..platform.path.kooiot
		delay_exec('upgrade.sh', {'cd /', platform.path.kooiot..'/run.sh stop', umount, mv, 'sleep 3', start, platform.path.kooiot..'/run.sh start'})
	else
		return nil, "Please select a local file first"
	end

	return true, 'System will be restarted soon'
end

--- Get latest version in store
-- @treturn number version
function _M.remote_version()
	local http = require 'socket.http'
	local store = require 'shared.store'

	http.TIMEOUT = 2
	local url = 'http://'..store.get_srv()..'/sys/version'
	local json, code = http.request(url)
	if code ~= 200 then
		return nil, 'Failed to download, return code: '..code..' url: '..url
	end
	local cjson = require 'cjson.safe'
	local version = cjson.decode(json)
	return version
end

--- Download system upgrade file from store
-- @tparam number version
-- @treturn string the downloaded file path
-- @treturn string error
local function download_sys(version)
	local version = version or 'latest'

	local store = require 'shared.store'
	local cfg = store.get_cfg()

	local src = cfg.srvurl..'/sys/kooiot_xz.'..version..'.sfs'
	local dest = platform.path.temp..'/kooiot.'..version..'.sfs'

	log:info('SYSTEM', "Download system from", src, "to", dest)
	local r, err = download(src, dest)
	if not r then
		log:warn('SYSTEM', "Download fails", err)
		return nil, err
	end
	return dest
end

--- Upgrade system to specified version
--  which will download the specified version from store and then upgrade it
--  @tparam number version
--  @treturn boolean result
--  @treturn string error
function _M.store_upgrade(version)
	local path, err = download_sys(version)
	if not path then
		return nil, err
	end
	return _M.upgrade(path)
end

return _M
