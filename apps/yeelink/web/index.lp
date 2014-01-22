<h1>
	YeeLink Platform data publisher
</h1>

<style>
	form { display: block; margin: 20px auto; background: #eee; border-radius: 10px; padding: 15px }
</style>

<form action="<?=rurl('api.lua')?>" method="post" enctype="multipart/form-data">
	<label> <h2>APP(<?=cgilua.QUERY.name?>)</h2> </label>
	<label> API KEY: </label>
	<input type="hidden" name="app" value="<?=cgilua.QUERY.name?>">
	<input type="text" name="key" value="">
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


