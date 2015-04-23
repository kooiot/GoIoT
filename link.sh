if [ -L /tmp/apps ]; then
	rm -f /tmp/apps
fi

if [ -L /tmp/core ]; then
	rm -f /tmp/core
fi

if [ -d /tmp/apps ]; then
	rm -rf /tmp/apps
fi
if [ -d /tmp/core ]; then
	rm -rf /tmp/core
fi

ln -s /home/cch/temp/apps /tmp/apps
ln -s /home/cch/temp/core /tmp/core
