#!/usr/bin/env sh

if [ -z $CAD_DIR ]; then
	export CAD_DIR=$(pwd)/../
fi

export LWF_ROOT=$CAD_DIR/web/lwf
export LWF_APP_NAME='v3'
export LWF_APP_PATH=$CAD_DIR/web/www

echo $CAD_DIR

cd wsapi/
wsapi -- --config=xavante.conf.lua
cd ../

exit 0
