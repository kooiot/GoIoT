--- All platform related constants 
--

local _M = {}

--- The path contants
_M.path = {}

_M.path.kooiot = os.getenv('KOOIOT_DIR') or '/tmp/kooiot'
--- The application folder path
_M.path.apps = os.getenv('KOOIOT_APPS_DIR') or '/tmp/apps'
--- The application default configuration folder path
_M.path.appdefconf = os.getenv('KOOIOT_APPCONF_DIR') or '/tmp/apps/_defconf'
--- The temperatly folder for uploading and so on
_M.path.temp = os.getenv('KOOIOT_TEMP_DIR') or '/tmp/apps/_upload'
--- The core application fold path
_M.path.core = os.getenv('KOOIOT_CORE_DIR') or '/tmp/core'

local function init()
	os.execute('mkdir -p '.._M.path.appdefconf)
	os.execute('mkdir -p '.._M.path.temp)
	os.execute('mkdir -p '.._M.path.core)
end

init()

return _M
