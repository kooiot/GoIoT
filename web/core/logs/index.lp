<style>
</style>

<script>
	$(document).ready(function() {
		var oTable = $('#logstable').dataTable({
			//"bStateSave": true,
		});

		newtimer = setInterval( function () {
			query_logs();
		}, 1000 );
		var timer_running = true;

		$("#clear").click(function() {
			oTable.fnClearTable();
		});
		$("#stop").click(function() {
			if (timer_running) {
				clearInterval(newtimer)
				timer_running = false;
			}
		});
		$("#start").click(function() {
			if(!timer_running) {
				newtimer = setInterval( function () {
					query_logs();
				}, 1000 );
				timer_running = true;
			}
		});

		query_logs();
	});
	function query_logs() {
		$.get("<?=url('logs/api.lua')?>", { type : 'logs' }, function(data){
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
					log.level ? log.level : "N/A",
					log.content ? log.content : "N/A",
					]);
			};
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

<input type="button" id="clear" name="clear" value="Clear">
<input type="button" id="stop" name="stop" value="Stop Refresh">
<input type="button" id="start" name="start" value="Start Refresh">

<table cellpadding="0" cellspacing="0" border="0" class="display" id="logstable">
	<thead>
		<tr>
			<th style="width: 300px">Timestamp</th>
			<th style="width: 60px">Source</th>
			<th style="width: 60px">Level</th>
			<th>Content</th>
		</tr>
	</thead>
	<tbody>
	</tbody>
</table>

