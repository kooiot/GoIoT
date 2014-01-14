<script>
	$(document).ready(function() {
		query_status();
	});
	function query_status() {
		$.get("<?=rurl('apps.lua')?>", {from : "web" }, function(data){
			$("#app_status").html(data);
		})
		.done(function() {
			//alert("Data Saved successfully!!");
		})
		.fail(function() {
			alert("Failed to list applications!!");
		});
	};

	function operateApp(action, key) {
		$.post("<?=rurl('api.lua')?>", { key: key, action:action },
		function(data){
			$("#info_output").html('<br>' + data);
		})
		.done(function() {
			//alert("Data Saved successfully!!");
		})
		.fail(function() {
			alert("Failed to post to api.lua!!");
		});
	};

	function debugApp(key) {
		var addr = $("#srv_addr").val()
		var port = $("#srv_port").val()
		$.post("<?=rurl('api.lua')?>", { key: key, action:'start', debug:'1', addr:addr, port:port},
		function(data){
			$("#info_output").html('<br>' + data);
		})
		.done(function() {
			//alert("Data Saved successfully!!");
		})
		.fail(function() {
			alert("Failed to post to api.lua!!");
		});

	};

</script>

<h1>
	Application status page
</h1>

<input id="refresh" type="button" value="Refresh" onClick="query_status()">

<br>
<div id="debug_settings">
	<label><b>Debug Settings</b></label>
	<br>
	<label>Addr:</label>
	<input id="srv_addr" type="text" value="172.30.11.237">
	<label>Port:</label>
	<input id="srv_port" type="text" value="8172">
</div>
<br>

<label> <b>Applications:</b> </label>
<div id="app_status">
</div>
<div id="info_output"></div>

