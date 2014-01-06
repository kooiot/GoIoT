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
			//alert("Failed to save content to file!!");
		});
	};

	function operateApp(action, key) {
		$.post("<?=rurl('event.lua')?>", { key: key, action:action },
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
	Application status page
</h1>

<input type="button" value="Refresh" onClick="query_status()">
<div id="app_status">
</div>


