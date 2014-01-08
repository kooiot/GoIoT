<h1>
	Application status page
</h1>

<%
	local api = require 'shared.api.configs'
	local data = api.version()
	if not data then
%>
		<h2> Query API failed </h2>
<%
	else
%>
		<label> Version </label>
<%
		for k,v in pairs(data) do
			put('<br/>')
			put(k)
			put(':')
			put(v)
		end
	end
%>
<br/>

<script>
	$(function() {
		$( "#btnset" ).click(function(){
			set_value();
		});

		$( "#btnget" ).click(function(){
			get_value();
		});
	});

	function set_value() {
		var key = $("#key").val();
		var value = $("#value").val();
		$.post("<?=url("configs/api.lua")?>", { key: key, value:value },
		function(data){
			$( "#status" ).html(data);
		})
		.done(function() {
			//alert("Data Saved successfully!!");
		})
		.fail(function() {
			$( "#status" ).html("<br> ERROR:failed to post");
		});
	};
	function get_value() {
		var key = $("#key").val();
		$.get("<?=url("configs/api.lua")?>", { key : key }, function(data) {
			$("#value").val();
			$("#value").val(data);
		})
		.done(function() {
			$( "#status" ).html("<br> Get value done");
		})
		.fail(function() {
			$( "#status" ).html("<br> ERROR:Failed to get value");
		});
	};

</script>
<div id=test>
	KEY: <input id="key" name="key" type="text"/>
	VALUE: <input id="value" name="value" type="text"/>
	<button id="btnget">Get</button>
	<button id="btnset">Set</button>
</div>

<div id = "status"></div>

