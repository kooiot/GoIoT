return function(con)
	local send = require('shared.msg.send')(con)
	local reply = require 'shared.msg.reply'

	return {
		send_result = send.result,
		send_err = send.err,
		reply = reply,
	}
end
