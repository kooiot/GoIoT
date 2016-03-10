local m_path = os.getenv('KOOIOT_DIR') or "."
local m_package_path = package.path  
package.path = string.format("%s;%s/?.lua;%s/?/init.lua", m_package_path, m_path, m_path)  

local loader = require('shared.util.lazy_loader')

local et = loader()
et:add('log', 'shared.log')
et:add('msg', 'shared.msg')
et:add('system', 'shared.system')
et:add('platform', 'shared.platform')

et:load(m_path..'/shared/util', 'shared', 'util')
et:load(m_path..'/shared/compat', 'shared', 'compat')
et:load(m_path..'/shared/api', 'shared', 'api')

return  et
