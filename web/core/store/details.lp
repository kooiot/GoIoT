
<ul id="cloudNav">
  <li id="appBestId"><a href="<?=url('store')?>" class="" hidefocus=""></a></li><!--精品-->
  <li id="appSoftId"><a href="<?=url('store')?>" class="checked" hidefocus=""></a></li><!-- 软件 -->
  <!--<li id="appGameId"><a href="http://app.meizu.com/cats/2/2/0" class="" hidefocus=""></a></li> -->
  <!--<li id="appThemeId"><a href="http://app.meizu.com/cats/5/6/0" class="" hidefocus=""></a></li> -->
  <li id="appBelongId"><a href="<?=url('store', {mode='i'})?>" class="" hidefocus=""></a></li><!--我的应用-->
</ul>

<div class="soft_ware">
<%
local app = nil 
if cgilua.QUERY.lname then
	local list = require 'shared.app.list'
	app =list.find(cgilua.QUERY.lname)
elseif cgilua.QUERY.name then
	local cloud = require 'shared.cloud'
	local t = cloud.search(cgilua.QUERY.name)
	for k, v in pairs(t) do
		if v.name == cgilua.QUERY.name then
			app = v
		end
	end
end

if not app then
%>
<b> Failed to fetch application information for [<?=cgilua.QUERY.name?>] </b>
<%
else
	put([[<h1> Application Details </h1>]])
	put('<br> Name:', app.name)
	put('<br> Description:', app.desc)
	put('<br> Manufactor:', app.manufactor)
	put('<br> Author:', app.author)
	put('<br> Version:', app.version)
	put('<br> Build:', app.build)
end
%>
</div>
