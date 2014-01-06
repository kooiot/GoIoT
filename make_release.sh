rm -rf __install
mkdir __install

cp -r core __install/core
cp -r shared __install/shared
cp -r web __install/web
cp run.sh __install/run.sh

cd __install/web/core
rm -f apps
ln -s /tmp/apps apps
cd ../../..

mkfs.cramfs __install cad2.cramfs

rm -rf __install
