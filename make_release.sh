# !/usr/bin/env sh

rm __release/* -rf
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

#################################
# Count the file sizes
################################
du __install -sh

VERSION=`git log --oneline | wc -l | tr -d ' '`
echo $VERSION > __install/version

# Compile lua files
# ./scripts/compile_lua.sh 

# Create the cramfs image
sudo chown -R root:root __install
#mkfs.cramfs __install __release/kooiot.$VERSION.cramfs
mksquashfs __install __release/core_gz.$VERSION.sfs
#mksquashfs __install __release/kooiot_mips.sfs -nopad -noappend -root-owned -comp xz -Xpreset 9 -Xe -Xlc 0 -Xlp 2 -Xpb 2
mksquashfs __install __release/core_xz.$VERSION.sfs -comp xz
# Clean up the rootfs files
sudo rm -rf __install

# Release example (modbus)
./scripts/release_app.sh example
# Release the yeelink
./scripts/release_app.sh yeelink
# Release cloud 
./scripts/release_app.sh cloud
# Release cloudex
./scripts/release_app.sh cloudex
# Release network
./scripts/release_app.sh network
# Release IR Controller
./scripts/release_app.sh ir
# Release Auto Control
./scripts/release_app.sh autoctrl
# Release Modbus
./scripts/release_app.sh modbus

# Done
echo 'DONE'
