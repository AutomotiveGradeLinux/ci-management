#!/bin/bash

#set -x
set -e

echo -e "\n\n\n"
echo "#########################################"
echo -e "\n\n\n"

#failsafe
if test x"" = x"${ALGBRANCH}" ; then
  echo "AGLBRANCH not defined"
  exit 1
fi
if test x"" = x"${MYPROJECT}"; then
  echo "MYPROJECT not defined"
  exit 1
fi
if test x"" = x"${BUILD_NUMBER}"; then
  echo "BUILD_NUMBER not defined"
  exit 1
fi
if test x"" = x"${GERRIT_CHANGE_NUMBER}"; then
  echo "GERRIT_CHANGE_NUMBER not defined"
  exit 1
fi
if test x"" = x"${TARGETARCH}"; then
  echo "TARGETARCH is not defined"
  exit 1
fi

# construct upload folder
#mv UPLOAD UPLOAD2 || true
rm -rf UPLOAD/* || true
mkdir -p UPLOAD/${MYPROJECT}/${AGLBRANCH}/${BUILD_NUMBER}-${GERRIT_CHANGE_NUMBER}/${TARGETARCH}
ln -sf ${BUILD_NUMBER}-${GERRIT_CHANGE_NUMBER} UPLOAD/${MYPROJECT}/${AGLBRANCH}/latest
export DEST=$(pwd)/UPLOAD/${MYPROJECT}/${AGLBRANCH}/${BUILD_NUMBER}-${GERRIT_CHANGE_NUMBER}/${TARGETARCH}

# copy the wgt to the upload folder
pushd ${MYPROJECT}
  pwd
  ls -alh || true
  ls package || true
  cp package/*.wgt $DEST
  ls -alh $DEST
popd
