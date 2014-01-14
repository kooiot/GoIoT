<?
	local name = cgilua.QUERY.name
?>

<style>
	.black { display: block; margin: 20px auto; background: #aaa; border-radius: 10px; padding: 15px }
	.gray { display: block; margin: 0px auto; background: #eee; border-radius: 10px; padding: 15px }
</style>

<script>
	$(function() {
		$( "#tabs" ).tabs();
		$( "#radio_1" ).buttonset();
		$( "#radio_2" ).buttonset();
	});

	function operateApp(action, key) {
		$.post("<?=url("status/app.lua")?>", { key: key, action:action },
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

	function post_config(key, data)
		$.post("<?=rurl('config.lua')?>", {name: '<?=name?>', key: key, data : JSON.stringify(data)}, function (data) {
			alert(data);
		})
		.done(function(data) {
		})
		.fail(function() {
		});

	end
</script>

<h1>
	IO APP - <? =name ?>
</h1>

<div class="black">
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
			%>
			<!--input type="button" value="Pause" onClick="operateApp('pause', '<?=name?>')"-->
			<input type="button" value="Reload" onClick="operateApp('reload', '<?=name?>')">
			<input type="button" value="Close" onClick="operateApp('close', '<?=name?>')">
			<a href="#"> Manage </a>
			<%
			put('</div>')
		else
			put('result incorrect')
		end
	end
%>
</div>
<%
local api = require('shared.api.app').new(port)
--[[
local version, err = api:version()
if not version then
	put('Api Error:', err)
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
		<div class="gray">
		<% rinclude('ports.lp', {ports = meta.app.ports, cgilua=cgilua, pairs=pairs, rurl=rurl}) %>	
		<% 
		--put(pp(meta.app.ports)) 
		%>
	</div>
	</div>
	<% if meta.app.settings and #meta.app.settings ~= 0 then %>
	<div id="tabs-settings">
		<% rinclude('settings.lp', {settings = meta.app.settings, cgilua=cgilua, pairs=pairs}) %>	
		<% 
		--put(pp(meta.app.settings)) 
		%>
	</div>
	<% end %>
	<div id="tabs-tags">
		<% rinclude('tags.lp', {tags = meta.app.tags, cgilua=cgilua, pairs=pairs, next=next, url=url, os=os, rurl=rurl, rinclude=rinclude}) %>	
		<% 
		--put(pp(meta.app.tags)) 
		%>
	</div>
	<% if meta.app.commands and #meta.app.commands ~= 0 then %>
	<div id="tabs-commands">
		<% rinclude('commands.lp', {commands = meta.app.commands, cgilua=cgilua, pairs=pairs}) %>	
		<%
		--put(pp(meta.app.commands)) 
		%>
	</div>
	<% end %>
</div>

<% rinclude('import.lp') %>	

<%
end
%>

