--- Loading the vars from file, which defines the symlink device object

local cjson = require 'cjson.safe'

local _M = {}

_M.conf = {}
local inputs = {}

local function  load_conf()
	local f, err = io.open('def.conf')
	if f then
		print(f)
		return cjson.decode(f:read('*a'))
	end
	return nil, err
end

function _M.load()
	local conf, err = load_conf()
	-- for testing
	if not conf then
		--return nil, err
		conf = {
			name = 'dev',
			desc = 'symlink device',
			inputs = {
				sn = {name='sn', desc='Serial Number of device', value='xxx-xxxx-xxxx-xxxxxxxx', ['type']='string/uuid'},
				modal = {name='modal', desc='Modal of device', value='Symlink V3 Test', ['type']='string'},
				time = {name='system time', desc='Device system time', value=os.time(), ['type']='number/time'}
			},
			commands = {
				reboot = 'reboot device'
			},
		}
	end

	_M.conf = conf
	return true
end

function _M.populate(db)
	local conf = _M.conf
	if not conf.name then
		return nil, 'No configuration'
	end
	local device = {
		name = conf.name, 
		desc = conf.desc,
		path = 'sys/'..conf.name,
		inputs = {},
		outputs = {},
		commands = {},
	}

	for k, v in pairs(conf.inputs) do
		local input = {
			path = device.path..'/inputs/'..k,
			name = v.name,
			desc = v.desc,
			value = v.value,
			props = {
				['type'] = {
					name='type',
					value=v['type'],
					desc='data type',
					path = device.path..'/'..k..'/props/type'
				}
			}
		}
		device.inputs[k] = input
		inputs[k] = input
		local r, err = db:set(input.path, input.value)
	end

	for k, v in pairs(conf.commands) do
		device.commands[k] = {
			path = device.path..'/'..k,
			name = k,
			desc = v,
		}
	end
	local verinfo = {
		app = {
			name = '__VARS',
			verion = '0.0.0' 
		},
		revision = '0',
	}

	return {name = 'sys', tree ={ devices = {[device.name] = device}, verinfo=verinfo}}
end

function _M.run(publish)
	for k, v in pairs(inputs) do
		if k == 'time' then
			publish(v.path, os.time())
		end
	end
end

return _M
