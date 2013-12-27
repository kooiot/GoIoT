<script>
	$(document).ready(function() {
		query_logs();
	});
	function query_logs() {
		$.get(<?=url('logs/api.lua')?>, { type : 'packets' }, function(data){
			$("textarea#output_box").val(data);
		})
		.done(function() {
			//$("textarea#output_box").append("Data Saved successfully!!\n");
			//alert("Data Saved successfully!!");
		})
		.fail(function() {
			//$("textarea#output_box").append("Failed to save content to file!!\n");
			//alert("Failed to save content to file!!");
		});
	}
</script>

<div id="output">
	<textarea id="output_box" name="output_box">
	</textarea>
</div>

<input type="button" value="Refresh" onClick="query_logs()">

