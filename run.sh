#!/usr/bin/env sh

if [ -z $CAD_DIR ]; then
	export CAD_DIR=$(pwd)
fi

export LWF_ROOT=$CAD_DIR/web/lwf
export LWF_APP_NAME='v3'
export LWF_APP_PATH=$CAD_DIR/web/www

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
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/core_iobus.pid --chdir $CAD_DIR/core/iobus --background --startas /usr/bin/lua -- start.lua
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/logs.pid --chdir $CAD_DIR/core/logs --background --startas /usr/bin/lua -- start.lua
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/web.pid --chdir $CAD_DIR/web/wsapi --background --startas /usr/local/bin/wsapi -- --config=xavante.conf.lua
else
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/web.pid --retry 5
	rm $PID_FOLDER/web.pid
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/logs.pid --retry 5
	rm $PID_FOLDER/logs.pid
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/core_iobus.pid --retry 5
	rm $PID_FOLDER/core_iobus.pid
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/core_monitor.pid --retry 5
	rm $PID_FOLDER/core_monitor.pid
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/core_config.pid --retry 5
	rm $PID_FOLDER/core_config.pid
fi

if [ -f /tmp/apps/_list ]; then
	while read line
	do
		eval "$line";
		echo $NAME $INSNAME $APPJSON
		$CAD_DIR/scripts/run_app.sh $1 $NAME $INSNAME
	done < /tmp/apps/_list
fi

exit 0
