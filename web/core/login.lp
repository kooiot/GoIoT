<html>
	<head>
		<title>Login</title>
		<link rel="stylesheet" type="text/css" href="/css/login/style.css">
		<link rel="stylesheet" type="text/css" href="/css/login/normalize.css">
	</head>
	<body>
		<div class="content">
			<section class="loginform cf">
			<form name="login" action="" method="post" accept-charset="utf-8">
				<ul>
					<%
					--[[
					<li>
					<label for="usermail">Email:</label>
					<input type="email" name="usermail" placeholder="yourname@email.com" required>
					</li>
					]]-- 
					%>
					<li>
					<label for="username">User:</label>
					<input type="text" name="username" placeholder="yourname" required>
					</li>
					<li>
					<label for="password">Password:</label>
					<input type="password" name="pass" placeholder="password" required></li>
					<li>
					<input type="submit" value="Login">
					</li>
				</ul>
			</form>
			</section>
		</div>
	</body>
</html>
