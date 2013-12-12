<%
cgilua.contentheader('text', 'html; charset=utf8')
%>

<!DOCTYPE html>
<html>
	<head>
		<title>OpenGate</title>

		<script src='http://cdn.staticfile.org/jquery/1.9.1/jquery.js'></script>
		<script src='http://cdn.staticfile.org/jqueryui/1.10.3/jquery-ui.js'></script>
		<script src='http://cdn.staticfile.org/jqueryui/1.10.3/css/base/jquery.ui.all.css'></script>
	</head>
	<body>
		<!--start container -->
		<div id="container">
			<header id="header">
			<nav>   
			<div id="logo">
				<a href="#"><img src="<?=cgilua.put('images/logo.png')?>" alt="Logo here" /></a> 
			</div>

			<div id="main_menu">
				<a href=<?=url('/')?>> Home </a>
				<a href=<?=url('system')?>> System </a>
				<a href=<?=url('status')?>> Status </a>	
			</div>
			</nav>
			</header>
			<div id="left_tree">
				<a href=<?=url('/')?>> Home </a>
				<a href=<?=url('system')?>> System </a>
				<a href=<?=url('status')?>> Status </a>	
				<a href=<?=url('status/apps.lp')?>> Applications </a>	
				<a href=<?=url('configs')?>> Configuration </a>	
			</div>

