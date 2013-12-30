<div>
<h1>Open Gate</h1>

<%
	local ver = require('_ver')
	if not ver then
	%>
		<p> Version information cannot be loaded </p>
	<%
	else
	%>
		<label> <b> <?=ver.desc?></b></label>
		</br>
		<label> Manufactor: </label>
		<?=ver.manufactor ?>
		</br>
		<label> Version: </label>
		<?=ver.version ?>
		</br>
		<label> Build: </label>
		<?=ver.build ?>
		</br>
	<%
	end
%>
</div>

