---
-- The application controler interface module
-- 

local zmq = require 'lzmq'
local cjson = require "cjson.safe"

local req = require 'shared.req'
local msg_reply = require 'shared.msg.reply'

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

function _M.find_app_port(appname)
	local mon = require 'shared.api.mon'
	local reply, err = mon.query({appname})
	if reply then
		if reply.status[appname] then
			return reply.status[appname].port
		end
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
