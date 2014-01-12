
<script type="text/javascript">
	var clikcFn = function(t,mydata){
		var status = $('#status');
		var jObj = $(this);
		if(this.id){
			var isin = jObj.attr('isin');
			if(isin=='1'){
				alert('install app');
				$.post("<?=rurl("store.lua")?>", {from:"web", action:"install", name:this.id, lname:this.id}, function(data) {
						alert(data);
				//	status.html('<br>' + data);
				})
				.done(function() {
				})
				.fail(function() {
					alert("Failed to install application");
				});
				} else {
				alert('uninstall app');
				$.post("<?=rurl("store.lua")?>", {from:"web", action:"uninstall", name:this.id}, function(data) {
					status.html('<br>' + data);
				})
				.done(function() {
				})
				.fail(function() {
					alert("Failed to uninstall application");
				});
			};
		};
	};

	$(document).ready(function(){
		$('.appCLKCls',$('#h_software')).bind('click',clikcFn);
	});
</script>

<ul id="cloudNav">
  <li id="appBestId"><a href="<?=url('store')?>" class="" hidefocus=""></a></li><!--精品-->
  <li id="appSoftId"><a href="<?=url('store')?>" class="checked" hidefocus=""></a></li><!-- 软件 -->
  <!--<li id="appGameId"><a href="http://app.meizu.com/cats/2/2/0" class="" hidefocus=""></a></li> -->
  <!--<li id="appThemeId"><a href="http://app.meizu.com/cats/5/6/0" class="" hidefocus=""></a></li> -->
  <li id="appBelongId"><a href="<?=url('store', {mode='i'})?>" class="" hidefocus=""></a></li><!--我的应用-->
</ul>


<style type="text/css">
.appTopSep{margin-left:20px;width:809;background-color:#dfdfdf;height:1px;overflow:hidden;}
</style>

	<div class="cloudRight">
<div class="soft_ware">
  <div class="categoryHead">
  		<div style="float:left;width:377px;height:80px;line-height:78px;padding-left:40px;">
	  		<span style="display:inline-block;width:60px;height:80px;">分类</span>
	  		<span style="display:inline-block;height:80px;position:relative;">
	  			<a style="display:inline-block;" id="x_selectCat" class="x_selectCat">全部</a>
	  			<span style="bottom: 33px;display: inline-block;right: -3px;" class="symAngle1"> </span>
	  		</span>
  		</div>
  		
  		<div class="x_payTypeCat x_Cat_0">
  			<span onclick="catsView.payAllFuc();"></span>
        	<span onclick="catsView.payFreeFuc();"></span>
        	<span onclick="catsView.payFuc();"></span>
       </div>
       <div class="x_orderType x_order_1">
  		<span id="orderSel1"></span>
  		<span id="orderSel3"></span>
  	</div>
  </div>
  
  <div class="body">
  
  	<div class="appTopSep"></div>
    <ul id="h_software" class="a_type2">
	<%
	local cloud = require 'shared.cloud'
	local mode = cgilua.QUERY.mode or 'a'
	local list = cloud.list(mode)
	for k,v in pairs(list) do
	%>
		<li>
		<div class="left">
			<a href="<?=rurl('details.lp', {name=v.name}) ?>"><img src="/images/app.png" alt="<?=v.name?>"></a>
		</div>
		<div class="right">
			<div class="title cutTitle" title="<?=v.name?>">
				<a href="<?=rurl('details.lp', {name=v.name}) ?>"><?=v.name?></a>
			</div>
			<div class="name" title="<?=v.manufactor?>"><?=v.manufactor?></div>
			<div class="starcls star41" sysver="Android4.2、Android4.1、Android4.0"></div>
			<% if mode == 'a' then %>
			<div title="安装此应用" isin="1" class="appCLKCls feebtn symBtnGray" id="<?=v.name?>">安装</div>
			<% else %>
			<div title="删除此应用" isin="0" class="appCLKCls feebtn symBtnGray" id="<?=v.name?>">删除</div>
			<% end %>
		</div>
		</li>
	<%
	end
	%>
    </ul>
       <div class="appTopSep"></div>
       
       <div style="clear:both;margin-bottom:30px;"></div>
	   <div id="symPager"><div class="pageDiv"><a class="selected bRadius0" href="#">1</a><a class="liNoThisClass bRadius2" href="#">2</a><a class="liNoThisClass bRadius2" href="#">3</a><a class="liNoThisClass bRadius2" href="#">4</a><a class="liNoThisClass bRadius2" href="#">5</a><a class="bRadius0 pomit" href="javascript:void(0)">...</a><a class="bRadius2 liNoThisClass" href="#" rno="183">183</a><a class="next bRadius2" href="#">下一页</a></div></div>
       <div class="blank32"></div>
  </div>
</div> 
</div>
<div id="status"></div>

