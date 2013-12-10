<h1>
	Status Pages
</h1>
<%
	local sysinfo = require 'sysinfo'
%>
<div id="sysdate">
	<label> OS Date </label>
	<?=os.date() ?>
</div>
<div id="syslocale">
	<label> Locale </label>
	<?=os.getenv('LANG') ?>
</div>
<div id="sysinfo_model">
	<label> CPU </label> 
	<?=sysinfo.cpu_model() ?> <br/>
	<label> Hostname </label> 
	<?=sysinfo.uname('-n') ?> <br/>
	<label> OS </label> 
	<?=sysinfo.uname('-s') ?> <br/>
	<label> Version </label> 
	<?=sysinfo.uname('-r') ?> <br/>
	<label> Memory </label>
	<?
		local mem = sysinfo.meminfo()
		put('total:'..mem.total)
		put('<br/>')
		put('used:'..mem.used)
		put('<br/>')
		put('free'..mem.free)
		put('<br/>')
	?>
	<label> Load Avg </label>
	<?
		local avg = sysinfo.loadavg()
		for k, v in pairs(avg) do
			put(k..':'..v)
			put('<br/>')
		end
	?>
	<label> Network </label>
	<?
		local ninfo = sysinfo.network()
		for ifname, v in pairs(ninfo) do
			put(ifname..'<br/>')
			for key, val in pairs(v) do
				put(key..':'..val)
				put('<br/>')
			end
		end
	?>
</div>
