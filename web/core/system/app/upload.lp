<h2>File Upload</h2>

<p>Choose the application pack file to install in this device.</p>
<form method="POST" enctype="multipart/form-data" action="<?=url("system/app/upload.lp")?>">
    <input type="file" name="file">
    <input type="submit" value="Upload">
</form>

<% 
	local apps_folder = os.getenv('CAD_APPS_DIR') or '/tmp/apps'
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
			<form method="POST" enctype="multipart/form-data" action="<?=url("system/app/upload.lp")?>">
				<input type="hidden" name="filename" value="<?=name?>">
				<input type="submit" name="remove" value="Remove">
				<input type="submit" name="install" value="Install">
            </form>
			<%
		else
			cgilua.print("Failed to save file, error", err)
        end
    end
%>

<%
	if cgilua.POST.install then
		local install = require 'shared.app.install'
		install(tmp_folder..'/'..cgilua.POST.filename, apps_folder, 'test__app')
        os.remove(tmp_folder..'/'..cgilua.POST.filename)
	end
%>
<%
    if cgilua.POST.remove then
        os.remove(tmp_folder..'/'..cgilua.POST.filename)
    end
%>
