<h1> System Upgrade </h1>

<h2>Upload from local disk</h2>

<p>Choose the application pack file to install in this device.</a>
<form method="POST" enctype="multipart/form-data" action=<?=url("system/sysupgrade.lp")?>>
    <input type="file" name="file">
    <input type="submit" value="Upload">
</form>

<% 
	local core_folder = os.getenv('CAD_CORE_DIR') or '/tmp/core'
	local tmp_folder = os.getenv('CAD_TEMP_DIR') or '/tmp/upload'

    local f = cgilua.POST.file
    if f and next(f) then
        local _, name = cgilua.splitonlast(f.filename)
        local file = f.file

        local dest, err = io.open(tmp_folder..'/'..name, "wb")
        if dest then
            local bytes = file:read("*a")
            dest:write(bytes)
            dest:close()
			--cgilua.print("<a href='"..name.."'>"..name.."</a>\n")
			cgilua.print("<b>"..name.."</b>\n")
			%>
			<form method="POST" enctype="multipart/form-data" action=<?=url("system/sysupgrade.lp")?>>
				<input type="hidden" name="filename" value="<?=name?>">
				<input type="submit" name="remove" value="Remove">
				<input type="submit" name="install" value="Upgrade">
            </form>
			<%
		else
			cgilua.print("Failed to save file, error", err)
        end
    end
%>

<%
	if cgilua.POST.install then
		--TODO: We need to first stop all services, then umount the cramfs. Thus we could use this mv
		os.execute('mv '..tmp_folder..'/'..cgilua.POST.filename..' '..core_folder)
	end
%>
<%
    if cgilua.POST.remove then
        os.remove(tmp_folder..'/'..cgilua.POST.filename)
    end
%>
