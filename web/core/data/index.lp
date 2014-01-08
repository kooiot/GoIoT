<script type="text/javascript">
	// for tag count changes
	var last_count = 0;
	$.fn.dataTableExt.oApi.fnReloadAjax = function ( oSettings, sNewSource, fnCallback, bStandingRedraw )
	{
		if ( typeof sNewSource != 'undefined' && sNewSource != null )
		{
			oSettings.sAjaxSource = sNewSource;
		}
		//this.oApi._fnProcessingDisplay( oSettings, true );
		// Do not show the process dialog....
		this.oApi._fnProcessingDisplay( oSettings, false );
		var that = this;
		var iStart = oSettings._iDisplayStart;

		oSettings.fnServerData( oSettings.sAjaxSource, [], function(json) {
				/* Clear the old information from the table */
				that.oApi._fnClearTable( oSettings );

				/* Got the data - add it to the table */
				for ( var i=0 ; i<json.tags.length ; i++ )
				{
					that.oApi._fnAddData( oSettings, json.tags[i] );
				}

				oSettings.aiDisplay = oSettings.aiDisplayMaster.slice();
				that.fnDraw( that );

				if ( typeof bStandingRedraw != 'undefined' && bStandingRedraw != true && last_count == json.tags.length )
				{
					oSettings._iDisplayStart = iStart;
					that.fnDraw( false );
				}
				last_count = json.tags.length;

				that.oApi._fnProcessingDisplay( oSettings, false );

				/* Callback user function - for event handlers etc */
				if ( typeof fnCallback == 'function' && fnCallback != null )
				{
					fnCallback( oSettings );
				}
		}, oSettings );
	}

	$(document).ready(function () {
		var oTable = $('#mytable').dataTable({
			"bProcessing": true,
			"bStateSave": true,
			//"bServerSide": true, // ServerSide true will append the columns name to server side with the get request
			"sAjaxSource": "<?=url('data/api.lua')?>",
			"sAjaxDataProp": "tags",
			"aoColumns": [
			{ "mDataProp": "name" },
			{ "mDataProp": "desc" },
			{ "mDataProp": "value" },
			{ "mDataProp": "timestamp" },
			]
		});
		newtimer = setInterval( function () {
			oTable.fnReloadAjax(null, null, false);
			}, 1000 );
		}); 
</script>

<h1> Test Page! </h1>
<div id="sysdate"><b>System Time:</b><u><%= os.date() %></u></div>
<br />
<p>User <%= cgilua.authentication.username() %> logged in <a href="<%= cgilua.authentication.logoutURL() %>">Logout</a> </p>
<button onclick="newtimer=window.clearInterval(newtimer)"> 停止刷新</button> 

<table cellpadding="0" cellspacing="0" border="0" class="display" id="mytable">
	<thead>
		<tr>
			<th>Name</th>
			<th>Description</th>
			<th>Value</th>
			<th>Timestamp</th>
		</tr>
	</thead>
	<tbody>

	</tbody>
	<tfoot>
		<tr>
			<th>Name</th>
			<th>Description</th>
			<th>Value</th>
			<th>Timestamp</th>
		</tr>
	</tfoot>
</table>

