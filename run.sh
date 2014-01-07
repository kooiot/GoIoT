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
do_start()
{
	# Return
	#   0 if daemon has been started
	#   1 if daemon was already running
	#   2 if daemon could not be started
	start-stop-daemon --start --quiet --make-pidfile --pidfile $PID_FOLDER/app_$NAME.pid --chdir /tmp/apps/$PROJECT --background --startas /usr/bin/lua -- start.lua $NAME --test > /dev/null \
		|| return 1
	start-stop-daemon --start --quiet --make-pidfile --pidfile $PID_FOLDER/app_$NAME.pid --chdir /tmp/apps/$PROJECT --background --startas /usr/bin/lua -- start.lua $NAME  \
		|| return 2
}

#
# Function that stops the daemon/service
#
do_stop()
{
	# Return
	#   0 if daemon has been stopped
	#   1 if daemon was already stopped
	#   2 if daemon could not be stopped
	#   other if a failure occurred
	start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PID_FOLDER/app_$NAME.pid
	RETVAL="$?"
	[ "$RETVAL" = 2 ] && return 2
	rm -f $PID_FOLDER/app_$NAME.pid
	return "$RETVAL"
}


if [ -f /tmp/apps/_list ]; then
	while read line
	do
		eval "$line";
		if [ $1 = "start" ] ; then
			#start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/app_$NAME.pid --chdir /tmp/apps/$PROJECT --background --startas /usr/bin/lua -- start.lua $NAME
			do_start
			case "$?" in
				0|1) [ "$VERBOSE" != no ] && echo "$NAME Already running" ;;
				2) [ "$VERBOSE" != no ] && echo "$NAME failed to start" ;;
			esac
		else
			#start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/app_$NAME.pid --retry 5
			#rm $PID_FOLDER/app_$NAME.pid
			do_stop
			case "$?" in
				0|1) [ "$VERBOSE" != no ] && echo "$NAME exited" ;;
				2) [ "$VERBOSE" != no ] && echo "Failed to close $NAME" ;;
			esac
		fi
	done < /tmp/apps/_list
fi

exit 0
