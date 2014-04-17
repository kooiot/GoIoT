<h1>
	YeeLink Platform data publisher
</h1>

<style>
	form { display: block; margin: 20px auto; background: #eee; border-radius: 10px; padding: 15px }
</style>
<%

local config = require 'shared.api.config'
local key = config.get(cgilua.QUERY.name..'.key') or '6015c744795762df41e9ebfa25fd625c'
%>
<form action="<?=rurl('api.lua')?>" method="post" enctype="multipart/form-data">
	<label> <h2>APP(<?=cgilua.QUERY.name?>)</h2> </label>
	<label> API KEY: </label>
	<input type="hidden" name="app" value="<?=cgilua.QUERY.name?>">
	<input type="text" name="key" value="<?=key?>">
	<input type="submit" value="SET">
</form>

<div id="status"></div>

<script>
	(function() {

		var status = $('#status');

		$('form').ajaxForm({
			beforeSend: function() {
				status.empty();
			},
			success: function() {
			},
			complete: function(xhr) {
				status.html(xhr.responseText);
			}
		}); 
	})();       
</script>

<%
	local port = cgilua.QUERY.port
	if port then
		local api = require('shared.api.app').new(port)
		local r, reply = api:request('list_devices')
		if not r  or not reply.devs then
			put('<br>', reply)
		else
			for k, v in pairs(reply.devs) do
			%>
			<div class='YeeLinkDevice'>
				<label><b> Device: <i><?=v.name?> </i></b></label>
				<a href='http://www.yeelink.net/devices/<?=v.id?>'> <u><span>Open in YeeLink</span></u> </a>
			</div>
			<%
			end
		end
	end
%>
