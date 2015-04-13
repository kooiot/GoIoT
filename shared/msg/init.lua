--- Socket Message helper utility functions module


--- Create an new helper object contains: send_result, send_err, reply
-- @function Module
-- @tparam object con the connection object which has send function
-- @treturn table 
return function(con)
	local send = require('shared.msg.send')(con)
	local reply = require 'shared.msg.reply'

	return {
		send_result = send.result,
		send_err = send.err,
		reply = reply,
	}
end

