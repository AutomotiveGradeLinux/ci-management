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

if test -d build/package ; then
  # use cmake build/package folder for wgt's ...
  ls build/package/ || true
  cp build/package/*.wgt $DEST
else
  # use just ./package/ for wgt's
  ls package || true
  cp package/*.wgt $DEST
fi


ls -alh $DEST

popd
