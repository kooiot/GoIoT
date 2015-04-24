#!/usr/bin/env sh

if [ -z $KOOIOT_DIR ]; then
	export KOOIOT_DIR=$(pwd)/../
fi

export LWF_ROOT=$KOOIOT_DIR/web/lwf
export LWF_APP_NAME='KooIoT'
export LWF_APP_PATH=$KOOIOT_DIR/web/www

echo $KOOIOT_DIR

cd wsapi/
wsapi -- --config=xavante.conf.lua
cd ../

exit 0
