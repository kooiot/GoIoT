<%
if not cgilua.authentication.username() then
	cgilua.redirect(cgilua.authentication.checkURL())
else
-- continues with the application flow
%>
<html>
	<head>
		<title>Login</title>
	</head>

	<body>

		dondoanfdafd

	</body>
</html>
<%
end
%>
