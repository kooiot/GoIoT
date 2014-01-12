<%
cgilua.contentheader('text', 'html; charset=utf-8')
%>

<!DOCTYPE html>
<html>
	<head>
		<title>OpenGate - <?=app?></title>

		<!-- CSS -->
		<link rel="stylesheet" type="text/css" href="css/styles.css">

		<link rel="stylesheet" type="text/css" href="css/header.css">
		<link rel="stylesheet" type="text/css" href="css/control.css">
		<link rel="stylesheet" type="text/css" href="css/cloud.css">
		<link rel="stylesheet" type="text/css" href="css/footer.css">

		<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
		<!-- Jquery -->
		<script type="text/javascript" charset="utf-8" src="http://cdn.staticfile.org/jquery/1.10.2/jquery.js"></script>

		<!-- Jquery Form -->
		<script type="text/javascript" charset="utf-8" src="js/jquery.form.min.js"></script>

		<!-- Jquery UI -->
		<link rel="stylesheet" type="text/css" href="http://cdn.staticfile.org/jqueryui/1.10.3/css/base/jquery.ui.all.css">
		<script type="text/javascript" charset="utf-8" src="http://cdn.staticfile.org/jqueryui/1.10.3/jquery-ui.js"></script>

		<!-- DataTables CSS -->
		<link rel="stylesheet" type="text/css" href="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.4/css/jquery.dataTables.css">
		<!-- DataTables -->
		<script type="text/javascript" charset="utf-8" src="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.4/jquery.dataTables.min.js"></script>
	</head>
	<body>
		<div id="container">
			<div id="header">
				<li class='active'><a href='/'><img src="/images/logo.png" alt="Logo here" /></a></li>
				<div id='cssmenu'>
					<ul>
						<li class='active'><a href="<?=url('/')?>"><span>Home</span></a>
						<li class='has-sub'><a href="<?=url('store')?>"><span>Store</span></a>
						<ul>
							<li class='last'><a href='<?=url("store/config.lp")?>'><span>Config</span></a></li>
						</ul>


						<li class='has-sub'><a href='<?=url("system/apps.lp")?>'><span>Applications</span></a>
						<ul>
							<% script('system/list_app.lua') %>
						</ul>

						<li class='has-sub'><a href='<?=url("system")?>'><span>System</span></a>
						<ul>
							<li class='no-sub'><a href="<?=url('configs')?>"><span>Configuration</span></a>
							<li class='last'><a href='<?=url("system/status.lp")?>'><span>System Information</span></a></li>
						</ul>

						</li>
						<li class='has-sub'><a href='<?=url("logs")?>'><span>Logs</span></a>
						<ul>
							<li><a href='<?=url("logs")?>'><span>Logs</span></a></li>
							<li class='last'><a href='<?=url("logs/packets.lp")?>'><span>Packets</span></a></li>
						</ul>
						</li>
						<li class='no-sub'><a href='<?=url("data")?>'><span>Data</span></a></li>

						<li class='has-sub'><a href='<?=url("user")?>'><span><?= cgilua.authentication.username() ?> User</span></a>
						<ul>
							<li class='last'><a href='<%= cgilua.authentication.logoutURL() %>'><span>Logout</span></a></li>
						</ul>
						</li>
						<li class='last'><a href='<?=url("about")?>'><span>About</span></a></li>
					</ul>
				</div>
			</div>
			<div id="body">

