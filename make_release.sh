# !/usr/bin/env sh

rm __release -rf
# Make the release folder
mkdir -p __release

# Clean up the cramfs folder
sudo rm -rf __install
mkdir __install

# Copy files
cp -r core __install/core
cp -r shared __install/shared
cp -r web __install/web
cp -r scripts __install/scripts
cp run.sh __install/run.sh
# remove the release the script
rm __install/scripts/release*
rm __install/scripts/code_backup.sh
rm __install/scripts/compile_lua.sh
# copy lwf files
cd __install/web
rm -f lwf
mkdir lwf
cp -r ../../web/lwf/* lwf/
rm -f wsapi
mkdir wsapi
cp -r ../../web/wsapi/* wsapi/
rm wsapi/shared
ln -s ../../shared wsapi/shared
cd ../..
# Correct the the soft link in web core
cd __install/web/www
rm -f apps
ln -s /tmp/apps apps
cd ../../..

# Compile lua files
# ./scripts/compile_lua.sh 

# Create the cramfs image
sudo chown -R root:root __install
#mkfs.cramfs __install __release/cad2.cramfs
mksquashfs __install __release/cad2.sfs
# Clean up the rootfs files
sudo rm -rf __install

# Release example (modbus)
./scripts/release_app.sh example
# Release the yeelink
./scripts/release_app.sh yeelink
# Release cloud 
./scripts/release_app.sh cloud

# Done
echo 'DONE'
