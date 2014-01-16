-- All platfor relate settings
--
local _M = {}

_M.path = {}

_M.path.apps = os.getenv('CAD_APPS_DIR') or '/tmp/apps'
_M.path.appdefconf = os.getenv('CAD_APPCONF_DIR') or '/tmp/apps/_defconf'
_M.path.temp = os.getenv('CAD_TEMP_DIR') or '/tmp/apps/_upload'
_M.path.core = os.getenv('CAD_CORE_DIR') or '/tmp/core'

return _M
