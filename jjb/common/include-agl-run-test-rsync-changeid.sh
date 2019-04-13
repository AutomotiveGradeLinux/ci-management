#!/bin/bash

#set -x
set -e

echo "\n\n\n"
echo "#########################################"
echo "\n\n\n"


export RSYNCDST="/srv/download/AGL/upload/ci/${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER}"
export RSYNCSRC=$(pwd)/UPLOAD/
export RSYNCSRCstorage=$(pwd)/UPLOADstorage/

# construct upload folder
mv UPLOAD UPLOAD2 || true
rm -rf UPLOAD2 || true
mkdir -p UPLOAD/${MACHINE}
export DEST=$(pwd)/UPLOAD/${MACHINE}

export DEST2=$(pwd)/UPLOADstorage/AGL/upload/ci/${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER}/
mkdir -p ${DEST2}

cd $REPODIR

cd output

pwd
ls -alhR tmp/deploy/images

set -x

echo "tmp/deploy/images/${TARGETMACHINE}/${DEVICE_DTB}"
echo "tmp/deploy/images/${TARGETMACHINE}/${DEVICE_DTB#"$DEVICE_KERNEL"-}"

# workaround for thud until fixed in templates:
if [ ! -e tmp/deploy/images/${TARGETMACHINE}/${DEVICE_DTB} -a -e tmp/deploy/images/${TARGETMACHINE}/${DEVICE_DTB#"$DEVICE_KERNEL"-} ] ; then
    cp -avL tmp/deploy/images/${TARGETMACHINE}/${DEVICE_DTB#"$DEVICE_KERNEL"-} tmp/deploy/images/${TARGETMACHINE}/${DEVICE_DTB}
fi

BUILD_INFO=build-info
# copy files to $DEST (only if variable is non-empty)
for i in DEVICE_DTB DEVICE_KERNEL DEVICE_INITRAMFS DEVICE_NBDROOT BUILD_INFO; do
    FILE=$(eval echo \$${i})
    if [ -n "$FILE" ]; then
      cp -avL tmp/deploy/images/${TARGETMACHINE}/${FILE} ${DEST}/
      cp -avL tmp/deploy/images/${TARGETMACHINE}/${FILE} ${DEST2}/
    fi
done
set +x

tree $DEST
ls -alhR $DEST

ssh -o StrictHostKeyChecking=no jenkins-slave@10.30.72.8 mkdir -p ${RSYNCDST}

rsync -avr -L -e "ssh -o StrictHostKeyChecking=no" $RSYNCSRC jenkins-slave@10.30.72.8:$RSYNCDST

