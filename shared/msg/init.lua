--- The socket message helper functions
-- @tparam object con the connection object which has send function
-- @treturn table the module table has send_result, send_err, reply
return function(con)
	local send = require('shared.msg.send')(con)
	local reply = require 'shared.msg.reply'

	return {
		send_result = send.result,
		send_err = send.err,
		reply = reply,
	}
end

