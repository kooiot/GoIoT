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
local pp = require 'shared.PrettyPrint'
local meta, err = api:meta()
if not meta then
	put('Api Error:', err)
else
	--put(pp(meta))
end
%>

<script>
	$(function() {
		$( "#tabs" ).tabs();
		$( "#radio1" ).buttonset();
		$( "#radio2" ).buttonset();
	});
</script>

<div id="tabs">
	<ul>
		<li><a href="#tabs-1">Port</a></li>
		<li><a href="#tabs-2">Settings</a></li>
		<li><a href="#tabs-3">Commands</a></li>
	</ul>
	<div id="tabs-1">
		<p>
		<% local index = 1 %>
		<%
		for k,v in pairs(meta.app.ports) do 
			local name = 'radio'..index
		%>
			<div class="port_conf">
				<label> <?=v.name ?> </label>
				<div id="<?=name?>">
					<input type="radio" id="radio1" name="<?=name?>" checked="checked"><label for="radio1">TCP Client</label>
					<input type="radio" id="radio2" name="<?=name?>"><label for="radio2">TCP Server</label>
					<input type="radio" id="radio3" name="<?=name?>"><label for="radio3">Serial</label>
				</div>

				<label for="ip1">Local IP: </label>
				<input type="text" id="ip1" name="ip1" value="<?=v.default.props.local_addr.value ?>"> 
				<label for="ip2">Remote IP: </label>
				<input type="text" id="ip2" name="ip2" value="<?=v.default.props.remote_addr.value ?>"> 
				<label for="port1">Port: </label>
				<input type="text" id="port1" name="port1" value="<?=v.default.props.port.value ?>"> 
			</div>
		<% 
			index = index + 1
		end
		%>
		</p>
		<p>
		<% 
		put(pp(meta.app.ports)) 
		%>
		</p>
	</div>
	<div id="tabs-2">
		<p>
		<% put(pp(meta.app.settings)) %>
		</p>
	</div>
	<div id="tabs-3">
		<p>
		<% put(pp(meta.app.commands)) %>
		</p>
	</div>
</div>

<input type="button" value="Save" onClick="alert('test')">

