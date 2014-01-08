<style>
</style>

<script>
	$(document).ready(function() {
		var oTable = $('#logstable').dataTable({
			"bStateSave": true,
		});

		newtimer = setInterval( function () {
			query_logs();
		}, 1000 );

		query_logs();
	});
	function query_logs() {
		$.get("<?=url('logs/api.lua')?>", { type : 'packets' }, function(data){
			var jdata = JSON.parse(data);
			var oTable = $('#logstable').dataTable();
			for (var i in jdata)
			{
				var log = JSON.parse(jdata[i])
				var unixTimestamp = new Date(log.timestamp) 
				var commonTime = unixTimestamp.toLocaleString() + ' ' +  (log.timestamp % 1000)
				oTable.fnAddData( [
					commonTime,
					log.src ? log.src : "N/A",
					log.desc ? log.desc : "N/A",
					log.content ? log.content : "N/A",
					]);
			} 
			var count = oTable.fnSettings().fnRecordsTotal();
			for (var i=1000; i < count; i++) {
				oTable.fnDeleteRow(0);
			}
		})
		.done(function() {
			//alert("Data Saved successfully!!");
		})
		.fail(function() {
			//alert("Failed to save content to file!!");
		});
	}
</script>

<table cellpadding="0" cellspacing="0" border="0" class="display" id="logstable">
	<thead>
		<tr>
			<th style="width: 280px">Timestamp</th>
			<th style="width: 60px">Source</th>
			<th style="width: 200px">Description</th>
			<th>Content</th>
		</tr>
	</thead>
	<tbody>
	</tbody>
</table>

