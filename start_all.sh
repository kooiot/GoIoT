cd app

cd rdb
./start.lua > /dev/null &
cd ..

cd test
./start.lua > /dev/null &
cd ..

cd ..

cd web
./start.sh > /dev/null &
cd ..

