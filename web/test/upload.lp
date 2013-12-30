<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
    <title>CGILua Test</title>
    <link rel="stylesheet" href="css/doc.css" type="text/css"/>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
    <%
    cgilua.cookies = require"cgilua.cookies"
    if cgilua.POST.user then
        cgilua.cookies.sethtml("cookie_kepler", cgilua.POST.user)
    end
    %>
</head>

<body>


<h2>File Upload</h2>

<p>Choose a file to upload, press "Upload" and a link to the file should
appear below with the corresponding "Remove" button.</a>
<form method="POST" enctype="multipart/form-data" action="upload.lp">
    <input type="file" name="file">
    <input type="submit" value="Upload">
</form>

<% 
    local f = cgilua.POST.file
    if f and next(f) then
		io.write(f.filename)
        local _, name = cgilua.splitonlast(f.filename)
		io.write(name)
        local file = f.file
        local dest = io.open(name, "wb")
        if dest then
            local bytes = file:read("*a")
            dest:write(bytes)
            dest:close()
            cgilua.print("<a href='"..name.."'>"..name.."</a>\n")
            cgilua.print([[<form method="POST" enctype="multipart/form-data" action="test.lp">]])
            cgilua.print([[<input type="hidden" name="filename" value="]]..name..[[">]])
            cgilua.print([[<input type="submit" name="remove" value="Remove">]])
            cgilua.print([[</form>]])
        end
    end
%>

<%
    if cgilua.POST.remove then
        os.remove(cgilua.POST.filename)
    end
%>

</body>
</html>
