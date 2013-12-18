#!/usr/bin/env sh

export CAD_DIR=$(pwd)
echo $CAD_DIR

if [ $# != 1 ] ; then
	echo "Usage: run.sh start|stop"
	exit 0
fi

echo $1

#PID_FOLDER=/var/run/
PID_FOLDER=/tmp/
if [ $1 = "start" ] ; then
	#start-stop-daemon --start --oknodo --name rdb --pidfile /var/run/rdb.pid --chdir ~/cad2/app/rdb --background --startas /usr/bin/lua5.2 -- start.lua
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/core_config.pid --chdir $CAD_DIR/core/config --background --startas /usr/bin/lua -- start.lua
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/core_monitor.pid --chdir $CAD_DIR/core/monitor --background --startas /usr/bin/lua -- start.lua
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/core_datacache.pid --chdir $CAD_DIR/core/datacache --background --startas /usr/bin/lua -- start.lua
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/app_io.pid --chdir $CAD_DIR/apps/io --background --startas /usr/bin/lua -- start.lua test 5515
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/app_io_2.pid --chdir $CAD_DIR/apps/io --background --startas /usr/bin/lua -- start.lua test2 5516
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/web.pid --chdir $CAD_DIR/web --background --startas /usr/local/bin/wsapi -- --cgilua
else
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/web.pid --retry 5
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/app_io.pid --retry 5
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/app_io_2.pid --retry 5
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/core_datacache.pid --retry 5
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/core_monitor.pid --retry 5
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/core_config.pid --retry 5
fi

exit 0
