<script>
	function save_ports() {
		var data = {
			<% for index,v in pairs(ports) do %>
			<?=v.name?> : { 
				name : '<?=v.name?>',
				type : "tcp_client", 
				props : { 
					local_addr :  $("#<?='lip'..index?>").val(), 
					remote_addr : $("#<?='rip'..index?>").val(),
					port : $("#<?='port'..index?>").val(),
				}
			},
			<% end %>
		};
		post_config('ports', data);
	};
</script>
<%
for index,v in pairs(ports) do 
	local name = 'radio_'..index
%>
	<div class="port_conf">
		<label> <b> 端口: <?=v.name ?> </b> </label>
		<div id="<?=name?>">
			<%
			for k, v in pairs(v.types) do
				if v == 'tcp_client' then
				%>		
				<input type="radio" id="<?=v..index ?>" name="<?=name?>" checked="checked"><label for="<?=v..index ?>" >TCP Client</label>
				<%
				end

				if v == 'tcp_server' then
				%>		
				<input type="radio" id="<?=v..index ?>" name="<?=name?>"><label for="<?=v..index ?>" >TCP Server</label>
				<%
				end

				if v == 'serial' then
				%>		
				<input type="radio" id="<?=v..index ?>" name="<?=name?>"><label for="<?=v..index ?>" >Serial</label>
				<%
				end
			end
			%>
		</div>
		
		<label for="<?='lip'..index ?>">Local IP: </label>
		<input type="text" id="<?='lip'..index ?>" name="<?='lip'..index ?>" value="<?=v.default.props.local_addr.value ?>"> 
		<label for="<?='rip'..index ?>">Remote IP: </label>
		<input type="text" id="<?='rip'..index ?>" name="<?='rip'..index ?>" value="<?=v.default.props.remote_addr.value ?>"> 
		<label for="<?='port'..index ?>">Port: </label>
		<input type="text" id="<?='port'..index ?>" name="<?='port'..index ?>" value="<?=v.default.props.port.value ?>"> 
	</div>
<% 
	index = index + 1
end
%>

<div class="black">
	<input type="button" id="save_port" value="Save" onClick="save_ports()">
</div>

