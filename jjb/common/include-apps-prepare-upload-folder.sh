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

if test x"$isAUTOBUILD" = x"1" ; then
  if [ "$(ls -l package/*.wgt | wc -l)" = "1" ] ; then
    echo "isAUTOBUILD"
    # use just ./package/ for wgt's
    ls package || true
    cp package/*.wgt $DEST
  elif [ "$(ls -l build/package/*.wgt | wc -l)" = "1" ] ; then
    # use just ./build/package/ for wgt's
    ls build/package || true
    cp build/package/*.wgt $DEST
  fi
fi
######################################################################
# /!\/!\/!\   DEPRECATED FALLBACK WAY TO BUILD AGL APPS /!\/!\/!\    #
######################################################################

if test x"$isCMAKE" = x"1" ; then
  echo "isCMAKE"
  # use cmake build/package folder for wgt's ...
  ls build/package/ || true
  cp build/package/*.wgt $DEST
fi
if test x"$isMAKE" = x"1" ; then
    echo "isMAKE"
    # use just ./package/ for wgt's
    ls package || true
    cp package/*.wgt $DEST
fi
if test x"$isQMAKE" = x"1" ; then
    echo "isQMAKE"
    # use just ./package/ for wgt's
    ls package || true
    cp package/*.wgt $DEST
fi


ls -alh $DEST

popd
