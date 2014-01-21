# !/usr/bin/env sh

sudo rm -rf __install
mkdir __install

cp -r core __install/core
cp -r shared __install/shared
cp -r web __install/web
cp -r scripts __install/scripts
cp run.sh __install/run.sh

rm __install/scripts/release*

rm -rf __install/web/test 
cd __install/web/core
rm -f apps
ln -s /tmp/apps apps
cd ../../..

sudo chown -R root:root __install
mkfs.cramfs __install cad2.cramfs
sudo rm -rf __install

./scripts/release_app.sh example
./scripts/release_app.sh yeelink

