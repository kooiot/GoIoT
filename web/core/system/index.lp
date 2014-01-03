<h1>
System Pages
</h1>

<style>
	form { display: block; margin: 20px auto; background: #eee; border-radius: 10px; padding: 15px }

	.progress { position:relative; width:600px; border: 1px solid #ddd; padding: 1px; border-radius: 3px; }
	.bar { background-color: #B4F5B4; width:0%; height:20px; border-radius: 3px; }
	.percent { position:absolute; display:inline-block; top:3px; left:48%; }
</style>

<form action="<?=rurl('upload.lua')?>" method="post" enctype="multipart/form-data">
	<label>Install App:</label>
	<input type="hidden" name="filetype" value="app">
	<input type="file" name="file">
	<input type="submit" value="Upload">
</form>

<form action="<?=rurl('upload.lua')?>" method="post" enctype="multipart/form-data">
	<label>System Upgrade:</label>
	<input type="hidden" name="filetype" value="sys">
	<input type="file" name="file">
	<input type="submit" value="Upload">
</form>

<div class="progress">
	<div class="bar"></div >
	<div class="percent">0%</div >
</div>

<div id="status"></div>

<script>
	(function() {

		var bar = $('.bar');
		var percent = $('.percent');
		var status = $('#status');

		$('form').ajaxForm({
			beforeSend: function() {
				status.empty();
				var percentVal = '0%';
				bar.width(percentVal);
				percent.html(percentVal);
			},
			uploadProgress: function(event, position, total, percentComplete) {
				var percentVal = percentComplete + '%';
				bar.width(percentVal);
				percent.html(percentVal);
				alert(percentVal);
			},
			success: function() {
				var percentVal = '100%';
				bar.width(percentVal)
				percent.html(percentVal);
			},
			complete: function(xhr) {
				status.html(xhr.responseText);
			}
		}); 

	})();       
</script>


