<h1>
	Application status page
</h1>

<%
	local mon = require 'shared.api.mon'
	local app_status = mon.query()
	if not app_status or app_status.result ~= 'ok' then
%>
		<h2> Query API failed <h2>
<%
	else
		for k,v in pairs(app_status.status) do
%>
		<label> Application: <?=k?> </label>
<%
		put(v.run and 'True' or 'False')
		put(os.date("%c", v.last))
		put('<br/>')
		end
	end
%>
