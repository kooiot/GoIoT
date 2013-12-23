<?
	local name = cgilua.QUERY.name
?>

<script>
	function operateApp(action, key) {
		$.post(<?=url("status/app.lua")?>, { key: key, action:action },
		function(data){
			alert(data);
		})
		.done(function() {
			//alert("Data Saved successfully!!");
		})
		.fail(function() {
			alert("Failed to post!!");
		});
	};
</script>

<h1>
	IO APP - <? =name ?>
</h1>

<%
	local port = cgilua.QUERY.port
	local mon = require 'shared.api.mon'
	local app_status, err = mon.query()
	if not app_status or not app_status.result then
		put('Query API failed:', err)
	else
		local v = app_status.status[name]
		if v then
			port = v.port
			put('<label> <b> Information </b> </label>')
			put('<div>')
			put('name:', name) 
			put('<br/>')
			put('Project:'..v.product)
			put('<br/>')
			put(v.run and 'True' or 'False')
			put('<br/>')
			put(v.port or 'None')
			put('<br/>')
			put(os.date("%c", v.last))
			put('<br/>')
			%>
			<input type="button" value="Start" onClick="operateApp('start', '<?=name?>')">
			<input type="button" value="Reload" onClick="operateApp('reload', '<?=name?>')">
			<input type="button" value="Stop" onClick="operateApp('stop', '<?=name?>')">
			<a href=<?=url(v.product, {name=name, port=v.port})?>> Manage </a>
			<%
			put('</div>')
		else
			put('result incorrect')
		end
	end
%>

<%
	local api = require('shared.api.app').new(port)
	local version, err = api:version()
	if not version then
		put('Api Error:', err)
	else
		put('<div>')
		put('version:', version.version)
		put('<br/>')
		put('build:', version.build)
		put('</div>')
	end
%>

<%
local meta, err = api:meta()
if not meta then
	put('Api Error:', err)
else
	local pp = require 'shared.PrettyPrint'
	put(pp(meta))
end
%>

