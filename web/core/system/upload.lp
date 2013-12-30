<h2>File Upload</h2>

<p>Choose a file to upload, press "Upload" and a link to the file should
appear below with the corresponding "Remove" button.</a>
<form method="POST" enctype="multipart/form-data" action=<?=url("system/upload.lp")?>>
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
        local dest, err = io.open('/tmp/'..name, "wb")
        if dest then
            local bytes = file:read("*a")
            dest:write(bytes)
            dest:close()
			cgilua.print("<a href='"..name.."'>"..name.."</a>\n")
			%>
			<form method="POST" enctype="multipart/form-data" action=<?=url("system/upload.lp")?>>
				<input type="hidden" name="filename" value="<?=name?>">
				<input type="submit" name="remove" value="Remove">
            </form>
			<%
		else
			cgilua.print("Failed to save file, error", err)
        end
    end
%>

<%
    if cgilua.POST.remove then
        os.remove('/tmp/'..cgilua.POST.filename)
    end
%>
