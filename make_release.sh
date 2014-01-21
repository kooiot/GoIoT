# !/usr/bin/env sh

# Make the release folder
mkdir -p __release

# Clean up the cramfs folder
sudo rm -rf __install
mkdir __install

# Copy cramfs files
cp -r core __install/core
cp -r shared __install/shared
cp -r web __install/web
cp -r scripts __install/scripts
cp run.sh __install/run.sh
# remove the release the script
rm __install/scripts/release*
# remove the web test files
rm -rf __install/web/test 
# Correct the the soft link in web core
cd __install/web/core
rm -f apps
ln -s /tmp/apps apps
cd ../../..

# Create the cramfs image
sudo chown -R root:root __install
mkfs.cramfs __install __release/cad2.cramfs
# Clean up the rootfs files
sudo rm -rf __install

# Release example (modbus)
./scripts/release_app.sh example
# Release the yeelink
./scripts/release_app.sh yeelink

# Done
echo 'DONE'
