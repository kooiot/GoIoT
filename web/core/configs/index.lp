<h1>
	Application status page
</h1>

<%
	local api = require 'shared.api.configs'
	local data = api.version()
	if not data then
%>
		<h2> Query API failed <h2>
<%
	else
%>
		<label> Version </label>
<%
		for k,v in pairs(data) do
			put('<br/>')
			put(k)
			put(':')
			put(v)
		end
	end
%>
