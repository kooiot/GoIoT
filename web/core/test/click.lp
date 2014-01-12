<script type="text/javascript">
	$(document).ready(function(){
			var clickFn = function(t, mydata) {
			alert("Bound handler called.");
			};
			$('.appCLKCls').bind('click', clickFn);
			});
</script>

<div class="body">
	<ul id="h_software" class="a_type2">
		<li>
		<div class="right">
			<div title="安装此应用" isin="1" class="appCLKCls feebtn symBtnGray" id="afada">安装</div>
		</div>
	</ul>
</div>

