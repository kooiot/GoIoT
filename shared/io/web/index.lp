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
			--[[
			put('<label> <b> Information </b> </label>')
			put('<div>')
			put('Name:', name) 
			put('<br/>')
			put('Description:', v.desc) 
			put('<br/>')
			put('Project:'..v.product)
			put('<br/>')
			put(v.run and 'True' or 'False')
			put('<br/>')
			put(v.port or 'None')
			put('<br/>')
			put(os.date("%c", v.last))
			put('<br/>')
			]]--
			%>
			<input type="button" value="Start" onClick="operateApp('start', '<?=name?>')">
			<input type="button" value="Reload" onClick="operateApp('reload', '<?=name?>')">
			<input type="button" value="Stop" onClick="operateApp('stop', '<?=name?>')">
			<a href="#"> Manage </a>
			<%
			put('</div>')
		else
			put('result incorrect')
		end
	end
%>

<%
	local api = require('shared.api.app').new(port)
	--[[
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
	]]--
%>

<%
local pp = require 'shared.PrettyPrint'
local meta, err = api:meta()
if not meta then
	put('Api Error:', err)
else
%>

<script>
	$(function() {
		$( "#tabs" ).tabs();
		$( "#radio_1" ).buttonset();
		$( "#radio_2" ).buttonset();
	});
</script>

<input type="button" value="Save" onClick="alert('test')">

<div id="tabs">
	<ul>
		<li><a href="#tabs-ports">Ports</a></li>
		<% if meta.app.settings and #meta.app.settings ~= 0 then %>
		<li><a href="#tabs-settings">Settings</a></li>
		<% end %>
		<li><a href="#tabs-tags">Tags</a></li>
		<% if meta.app.commands and #meta.app.commands ~= 0 then %>
		<li><a href="#tabs-commands">Commands</a></li>
		<% end %>
	</ul>
	<div id="tabs-ports">
		<% rinclude('ports.lp', {ports = meta.app.ports, cgilua=cgilua, pairs=pairs}) %>	
		<% 
		put(pp(meta.app.ports)) 
		%>
	</div>
	<% if meta.app.settings and #meta.app.settings ~= 0 then %>
	<div id="tabs-settings">
		<% rinclude('settings.lp', {settings = meta.app.settings, cgilua=cgilua, pairs=pairs}) %>	
		<% put(pp(meta.app.settings)) %>
	</div>
	<% end %>
	<div id="tabs-tags">
		<% rinclude('tags.lp', {tags = meta.app.tags, cgilua=cgilua, pairs=pairs, next=next, url=url, os=os, rurl=rurl}) %>	
	</div>
	<% if meta.app.commands and #meta.app.commands ~= 0 then %>
	<div id="tabs-commands">
		<% rinclude('commands.lp', {commands = meta.app.commands, cgilua=cgilua, pairs=pairs}) %>	
		<% put(pp(meta.app.commands)) %>
	</div>
	<% end %>
</div>

<%
end
%>

