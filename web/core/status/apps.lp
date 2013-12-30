<h1>
	Application status page
</h1>

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

<%
	local mon = require 'shared.api.mon'
	local app_status = mon.query()
	if not app_status or not app_status.result then
%>
		<h2> Query API failed </h2>
<%
	else
		for k,v in pairs(app_status.status) do
%>
		<p>
		<label> Application: <b> <?=k?> </b> </label>
<%
		put('<br/>')
		put('Project:'..v.product)
		put('<br/>')
		put('Description:'..v.desc)
		put('<br/>')
		put(v.run and 'True' or 'False')
		put('<br/>')
		put(v.port or 'None')
		put('<br/>')
		put(os.date("%c", v.last))
		put('<br/>')
		%>
		<input type="button" value="Start" onClick="operateApp('start', '<?=k?>')">
		<input type="button" value="Reload" onClick="operateApp('reload', '<?=k?>')">
		<input type="button" value="Stop" onClick="operateApp('stop', '<?=k?>')">
		<a href=<?=url('apps/'..v.product..'/web', {name=k, port=v.port})?>> Manage </a>
		</p>
		<%
		end
	end
%>

