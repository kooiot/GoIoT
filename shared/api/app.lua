---
-- The application controler interface module
-- 

local zmq = require 'lzmq'
local cjson = require "cjson.safe"

local req = require 'shared.req'
local msg_reply = require 'shared.msg.reply'
local exec = require 'shared.compat.execute'

local get_reply = function(json, err)
	if not json then
		return nil, err
	end
	return msg_reply(json)
end

--- Interface class
-- @type class
local class = {}

--- Get version of application
function class:version()
	local req = {'version', {from='web'}}

	return get_reply( self.client:request(cjson.encode(req), true) )
end

--- Get application status
-- @tparam string request method, nil for status
function class:status(request)
	local request = request or 'status'
	local req = {request, {from='web'}}
	return get_reply( self.client:request(cjson.encode(req), true) )
end

--- Pause the application
function class:pause()
	return self:status('pause')
end

--- Close the application
function class:close()
	return self:status('close')
end

--- Close the application
function class:reload()
	return self:status('reload')
end

--- Get meta information of application
function class:meta()
	local req = {'meta', {from='web'}}
	return get_reply( self.client:request(cjson.encode(req), true) )
end

--- Trigger import operation 
function class:import(filename)
	local vars = {filename=filename}
	return self:request('import', vars)
end

--- Send customized request to application
-- @tparam string msg Message method name
-- @tparam table vars Message varaiables
-- @treturn reply object
-- @treturn string error message
function class:request(msg, vars)
	local req = {msg, vars}
	return get_reply( self.client:request(cjson.encode(req), true) )
end

--- Close the connection manually (save memory usage)
--
function class:close()
	self.client:close()
	self.client = nil
end

--- Module
-- @section
local _M = {}

--- Find application mangement port
-- @tparam string appname application instance name 
-- @return port or nil if instance is not running or not installed
function _M.find_app_port(appname)
	local mon = require 'shared.api.mon'
	local status, err = mon.query({appname})
	if status then
		if status[appname] then
			return status[appname].port
		end
	end
end

--- Stop application by instance name
-- @tparam string insname application instance name
-- @treturn boolean result
-- @treturn string error message
function _M.stop(insname)
	local event = require('shared.event').C.new()
	event:open()
	--[[
	local log = require 'shared.log'
	log:info('STORE', "Stoping application "..lname)
	]]--
	return event:send({src='API', name='close', dest=insname})
end

--- Start application by instance name
-- @tparam string insname application instance name
-- @tparam boolean debug whether start the application in debug mode
-- @treturn boolean result
-- @treturn string error message
function _M.start(insname, debug)
	local list = require 'shared.app.list'
	list.reload()

	local app = list.find(insname)
	if not app then
		return nil, 'The application['..insname..'] is not installed'
	else
		local caddir = require('shared.platform').path.cad
		local cmd = caddir..'/scripts/run_app.sh start '..app.name..' '..insname
		if debug then
			if debug.addr then
				local file, err = io.open('/tmp/apps/_debug', "w")
				if file then
					local pp = require 'shared.PrettyPrint'
					local cfg = {}
					cfg.addr = debug.addr
					cfg.port = debug.port or 8172
					file:write('return '..pp(cfg)..'\n')
					file:close()
					cmd = cmd..' -debug'
				else
					return nil, err
				end
			else
				return nil, "Incorrect debug post"
			end
		end

		--[[
		local log = require 'shared.log'
		log:debug(ioname, "Running application", cmd)
		]]--

		local r, code = exec(cmd)
		return r, code
	end
end


--- Create new api instance 
-- @tparam number port Application management port
-- @treturn class api object
function _M.new(port)
	local client = req.new()
	client:open({zmq.REQ, linger = 0, connect = "tcp://localhost:"..port, rcvtimeo = 300}, 3)
	return setmetatable({client=client}, {__index=class})
end

return _M
