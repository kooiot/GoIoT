<h1>
System Pages
</h1>

<style>
	form { display: block; margin: 20px auto; background: #eee; border-radius: 10px; padding: 15px }
</style>

<form action="<?=rurl('store.lua')?>" method="post">
	<input type="hidden" name="action" value="config">
	<label> Server: </label>
	<input type="text" name="url" value="http://172.30.11.148/"> 
	<input type="submit" value="Change">
	<input type="button" name="update" id="update" value="Update">
</form>

<form action="<?=rurl('store.lua')?>" method="post">
	<input type="hidden" name="action" value="search">
	<label> Key: </label>
	<input type="text" name="key" value=""> 
	<input type="submit" value="Search">
</form>


<div id="status"></div>

<script>
	(function() {
		var status = $('#status');

		$('form').ajaxForm({
			beforeSend: function() {
				status.empty();
			},
			complete: function(xhr) {
				status.html('<br>' + xhr.responseText);
			}
		}); 

		$( "#update" ).click(function() {
			$.post("<?=rurl("store.lua")?>", {from:"web", action:"update"}, function(data) {
				status.html('<br>' + data);
			})
			.done(function() {
			})
			.fail(function() {
				alert("Failed to reboot");
			});
		});
	})();       
</script>


