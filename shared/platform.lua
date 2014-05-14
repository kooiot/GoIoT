--- All platform related constants 
--

local _M = {}

--- The path contants
_M.path = {}

--- The application folder path
_M.path.apps = os.getenv('CAD_APPS_DIR') or '/tmp/apps'
--- The application default configuration folder path
_M.path.appdefconf = os.getenv('CAD_APPCONF_DIR') or '/tmp/apps/_defconf'
--- The temperatly folder for uploading and so on
_M.path.temp = os.getenv('CAD_TEMP_DIR') or '/tmp/apps/_upload'
--- The core application fold path
_M.path.core = os.getenv('CAD_CORE_DIR') or '/tmp/core'

local function init()
	os.execute('mkdir -p '.._M.path.core)
end

init()

return _M
