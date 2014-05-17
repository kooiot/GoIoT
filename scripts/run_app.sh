NAME=$2
INSNAME=$3

if [ -z $CAD_DIR ]; then
	CAD_DIR=/tmp/cad2
fi
if [ -z $FID_FOLDER ]; then
	PID_FOLDER=/tmp/
fi

# Only run the application if main.lua exists
if [-f /tmp/apps/main.lua ]; then
	if [ $1 = "start" ] ; then
		start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/app_$INSNAME.pid --chdir /tmp/apps/$INSNAME --background --startas /usr/bin/lua -- start.lua $INSNAME $4 $5 $6 $7
	else
		start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/app_$INSNAME.pid --retry 5
		rm $PID_FOLDER/app_$INSNAME.pid
	fi
fi
