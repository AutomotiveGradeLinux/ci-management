#!/bin/bash

#set -x
set -e

echo -e "\n\n\n"
echo "#########################################"
echo -e "\n\n\n"

#failsafe
if test x"" = x"${AGLBRANCH}" ; then
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

PROJECTDIR="${AGLBRANCH}/${MYPROJECT}/${TARGETARCH}/"
PROJECTPATTERN="${PROJECTDIR}/changeset-${GERRIT_CHANGE_NUMBER}"

mkdir -p UPLOAD/${PROJECTPATTERN}
ln -sf changeset-${GERRIT_CHANGE_NUMBER} UPLOAD/${PROJECTDIR}/latest
export DEST=$(pwd)/UPLOAD/${PROJECTPATTERN}

# copy the wgt to the upload folder
pushd ${MYPROJECT}
pwd
if test -d build/package ; then
  # use cmake build/package folder for wgt's ...
  ls build/package/ || true
  cp build/package/*.wgt $DEST
else
  # use just ./package/ for wgt's
  ls package || true
  cp package/*.wgt $DEST
fi
popd

