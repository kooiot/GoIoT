NAME=$1
INSNAME=$2


if [ -z $CAD_DIR ]; then
	CAD_DIR=/tmp/cad2
fi
if [ -z $FID_FOLDER ]; then
	PID_FOLDER=/tmp/
fi

if [ $3 = "start" ] ; then
	start-stop-daemon --start --oknodo --make-pidfile --pidfile $PID_FOLDER/app_$INSNAME.pid --chdir /tmp/apps/$NAME --background --startas /usr/bin/lua -- $CAD_DIR/shared/app/run.lua $INSNAME
else
	start-stop-daemon --stop --oknodo --pidfile $PID_FOLDER/app_$INSNAME.pid --retry 5
	rm $PID_FOLDER/app_$INSNAME.pid
fi

