#!/bin/sh

if [ -z $KOOIOT_DIR ]; then
	export KOOIOT_DIR=$(pwd)
fi

export LWF_ROOT=$KOOIOT_DIR/web/lwf
export LWF_APP_NAME='v3'
export LWF_APP_PATH=$KOOIOT_DIR/web/www

# The fix for openwrt. The path does not includes the /usr/sbin in its system env
export PATH=/usr/sbin:/sbin:$PATH

echo $KOOIOT_DIR

if [ $# != 1 ] ; then
	echo "Usage: run.sh start|stop"
	exit 0
fi

WSAPI_PATH=/usr/bin/wsapi
if [ -f /usr/local/bin/wsapi ]; then
	WSAPI_PATH=/usr/local/bin/wsapi
fi

echo $1

cat /proc/sys/net/ipv4/ip_local_port_range > /tmp/port_range

#PID_FOLDER=/var/run/
PID_FOLDER=/tmp/
if [ $1 = "start" ] ; then
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/core_logs.pid --chdir $KOOIOT_DIR/core/logs --background --startas /usr/bin/lua -- start.lua -- logs
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/core_services.pid --chdir $KOOIOT_DIR/core/services --background --startas /usr/bin/lua -- start.lua -- services
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/core_config.pid --chdir $KOOIOT_DIR/core/config --background --startas /usr/bin/lua -- start.lua -- config
	# make sure config has enough time to startup
	sleep 1
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/core_monitor.pid --chdir $KOOIOT_DIR/core/monitor --background --startas /usr/bin/lua -- start.lua -- monitor
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/core_iobus.pid --chdir $KOOIOT_DIR/core/iobus --background --startas /usr/bin/lua -- start.lua -- iobus
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/core_web.pid --chdir $KOOIOT_DIR/web/wsapi --background --startas $WSAPI_PATH -- --config=xavante.conf.lua
else
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/core_web.pid --retry 5
	rm $PID_FOLDER/core_web.pid
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/core_iobus.pid --retry 5
	rm $PID_FOLDER/core_iobus.pid
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/core_monitor.pid --retry 5
	rm $PID_FOLDER/core_monitor.pid
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/core_config.pid --retry 5
	rm $PID_FOLDER/core_config.pid
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/core_services.pid --retry 5
	rm $PID_FOLDER/core_services.pid
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/core_logs.pid --retry 5
	rm $PID_FOLDER/core_logs.pid
fi

if [ -f /tmp/apps/_list ]; then
	while read line
	do
		eval "$line";
		echo $NAME $INSNAME $APPJSON
		$KOOIOT_DIR/scripts/run_app.sh $1 $NAME $INSNAME
	done < /tmp/apps/_list
fi
  
exit 0
