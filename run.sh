#!/usr/bin/env sh

if [ -z $CAD_DIR ]; then
	export CAD_DIR=$(pwd)
fi

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
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/logs.pid --chdir $CAD_DIR/core/logs --background --startas /usr/bin/lua -- start.lua
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/web.pid --chdir $CAD_DIR/web --background --startas /usr/local/bin/wsapi -- --cgilua
else
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/web.pid --retry 5
	rm $PID_FOLDER/web.pid
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/logs.pid --retry 5
	rm $PID_FOLDER/logs.pid
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/core_datacache.pid --retry 5
	rm $PID_FOLDER/core_datacache.pid
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/core_monitor.pid --retry 5
	rm $PID_FOLDER/core_monitor.pid
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/core_config.pid --retry 5
	rm $PID_FOLDER/core_config.pid
fi

# run all applications

if [ -f /tmp/apps/_list ]; then
	while read line
	do
		eval "$line";
		if [ $1 = "start" ] ; then
			start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/app_$NAME.pid --chdir $CAD_DIR/apps/$PROJECT --background --startas /usr/bin/lua -- start.lua $NAME
		else
			start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/app_$NAME.pid --retry 5
			rm $PID_FOLDER/app_$NAME.pid
		fi
	done < /tmp/apps/_list
fi

exit 0
