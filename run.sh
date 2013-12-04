#!/usr/bin/env sh

if [ $# != 1 ] ; then
	echo "Usage: run.sh start|stop"
	exit 0
fi

echo $1

#PID_FOLDER=/var/run/
PID_FOLDER=/tmp/
if [ $1 = "start" ] ; then
	#start-stop-daemon --start --oknodo --name rdb --pidfile /var/run/rdb.pid --chdir ~/cad2/app/rdb --background --startas /usr/bin/lua5.2 -- start.lua
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/rdb.pid --chdir ~/cad2/app/rdb --background --startas /usr/bin/lua -- start.lua
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/test.pid --chdir ~/cad2/app/test --background --startas /usr/bin/lua -- start.lua
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/test_pub.pid --chdir ~/cad2/app/test_pub --background --startas /usr/bin/lua -- start.lua
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/web.pid --chdir ~/cad2/web --background --startas /usr/local/bin/wsapi -- --cgilua
else
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/rdb.pid --retry 5
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/test.pid --retry 5
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/test_pub.pid --retry 5
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/web.pid --retry 5
fi
