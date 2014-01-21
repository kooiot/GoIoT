mkdir -p ../cad2_backup
git archive master | tar -x -C ../cad2_backup
cd ../
tar -zcf cad2/__release/cad2.tar.gz cad2_backup
rm -rf cad2_backup
cd cad2

