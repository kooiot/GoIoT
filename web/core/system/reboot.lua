local delay_exec = require 'shared.delay_exec'

local from = cgilua.POST.from

if not from then
	cgilua.print('<br> Incorrect POST found!!!')
else
	cgilua.print('<br> Rebooting...')
	--os.execute('echo "sleep 3;" >> /tmp/reboot.sh; echo "reboot" >> /tmp/reboot.sh; sh /tmp/reboot.sh &')
	delay_exec('reboot.sh', 'reboot')
end
