#!/bin/bash

#set -x
set -e

echo -e "\n\n\n"
echo "#########################################"
echo -e "\n\n\n"



# construct upload folder
#mv UPLOAD UPLOAD2 || true
if test x"" = x"${AGLBRANCH}" ; then
  rm -rf UPLOAD/${TARGETARCH} || true
  mkdir -p UPLOAD/${TARGETARCH}
  export DEST=$(pwd)/UPLOAD/${TARGETARCH}
else
  rm -rf UPLOAD/${AGLBRANCH}/${TARGETARCH} || true
  mkdir -p UPLOAD/${AGLBRANCH}/${TARGETARCH}
  export DEST=$(pwd)/UPLOAD/${AGLBRANCH}/${TARGETARCH}
fi

pushd ${MYPROJECT}
pwd

ls -alh

ls

ls package || true

cp package/*.wgt $DEST
ls -alh $DEST

popd
