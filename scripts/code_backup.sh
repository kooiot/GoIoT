mkdir -p ../v3_backup
git archive master | tar -x -C ../v3_backup
cd ../
tar -zcf v3/__release/code.tar.gz v3_backup
rm -rf v3_backup
cd v3

