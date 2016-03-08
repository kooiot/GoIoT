local m_path = os.getenv('KOOIOT_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

local loader = require('shared.util.lazy_loader')

local et = loader()
et.package('log', 'shared.log')
et.package('msg', 'shared.msg')
et.package('system', 'shared.system')
et.package('platform', 'shared.platform')

local util = loader()
util.load(m_path..'/shared/util', 'shared.util')
et.package('util', util)

local compat = loader()
compat.load(m_path..'/shared/compat', 'shared.compat')
et.package('compat', compat)

local api = loader()
api.load(m_path..'/shared/api', 'shared.api')
et.package('api', api)

return {
	app = et,
}
