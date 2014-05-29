---
-- The application controler interface module
-- 

local zmq = require 'lzmq'
local cjson = require "cjson.safe"

local req = require 'shared.req'

--- Interface class
-- @type class
local class = {}

--- Get version of application
function class:version()
	local req = {'version', {from='web'}}
	local reply, err = self.client:request(cjson.encode(req), true)

	if reply then
		reply = cjson.decode(reply)[2]
	end
	-- reply = { version=xxx, build=xxxx }
	return reply, err
end

--- Get application status
-- @tparam string request method, nil for status
function class:status(request)
	local request = request or 'status'
	local req = {request, {from='web'}}
	local reply, err = self.client:request(cjson.encode(req), true)

	if reply then
		reply = cjson.decode(reply)[2]
		-- reply = { result=xx, status=xxxx }
		if reply.result then
			reply = reply.status
		else
			reply = nil
			err = 'result is not true'
		end
	end
	return reply, err
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
	local reply, err = self.client:request(cjson.encode(req), true)

	if reply then
		reply = cjson.decode(reply)[2]
		-- reply = { result=xx, meta={blabla} }
		if reply.result then
			reply = reply.meta
		else
			reply = nil
			err = 'result is not true'
		end
	end
	return reply, err
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
	local reply, err = self.client:request(cjson.encode(req), true)
	if reply then
		reply = cjson.decode(reply)[2]
		if reply.result then
			return reply
		else
			err = reply.err
			reply = reply.result
		end
	end
	return reply, err
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
