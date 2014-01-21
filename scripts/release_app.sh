
if [ $# != 1 ] ; then
	echo "Usage: release.sh <app name>"
	exit 0
fi

cd ./apps/$1
zip -r -q ../../__release/$1.zip *
cd ../../
mkdir -p /var/www/master/$1
cp __release/$1.zip /var/www/master/$1/latest.zip
