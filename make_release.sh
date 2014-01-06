# !/usr/bin/env sh

sudo rm -rf __install
mkdir __install

cp -r core __install/core
cp -r shared __install/shared
cp -r web __install/web
cp run.sh __install/run.sh

cd __install/web/core
rm -f apps
ln -s /tmp/apps apps
cd ../../..

sudo chown -R root:root __install
mkfs.cramfs __install cad2.cramfs
sudo rm -rf __install

#scp cad2.cramfs user@172.30.11.135:~/
