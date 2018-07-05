#!/bin/bash

#set -x
set -e

echo -e "\n\n\n"
echo "#########################################"
echo -e "\n\n\n"



# construct upload folder
#mv UPLOAD UPLOAD2 || true
rm -rf UPLOAD/${AGLBRANCH} || true
mkdir -p UPLOAD/${AGLBRANCH}/
export DEST=$(pwd)/UPLOAD/${AGLBRANCH}/

ls -alh

cp  src/gerrit.automotivelinux.org/gerrit/${GERRIT_PROJECT}/*.zip $DEST

ls -alh $DEST

popd
