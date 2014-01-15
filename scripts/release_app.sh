
if [ $# != 1 ] ; then
	echo "Usage: release.sh <app name>"
	exit 0
fi

cd ./apps/$1
zip -r ../../$1.zip *
cd ../../
cp $1.zip /var/www/master/$1/latest.zip
