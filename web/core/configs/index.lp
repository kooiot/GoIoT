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
		$.post(<?=url("configs/api.lua")?>, { key: key, value:value },
		function(data){
			alert(data);
		})
		.done(function() {
			//alert("Data Saved successfully!!");
		})
		.fail(function() {
			alert("Failed to save!!");
		});
	};
	function get_value() {
		var key = $("#key").val();
		$.get(<?=url("configs/api.lua")?>, { key : key }, function(data) {
			$("#value").val();
			$("#value").val(data);
		})
		.done(function() {
		})
		.fail(function() {
			alert("Failed to get!!");
		});
	};

</script>
<div id=test>
	KEY: <input id="key" name="key" type="text"/>
	VALUE: <input id="value" name="value" type="text"/>
	<button id="btnget">Get</button>
	<button id="btnset">Set</button>
</div>

