#!/bin/bash

#set -x
set -e

echo "\n\n\n"
echo "#########################################"
echo "\n\n\n"


export RSYNCDST="/srv/download/AGL/upload/ci/${RELEASE_BRANCH}/${RELEASE_VERSION}"
export RSYNCSRC=$(pwd)/UPLOAD/

# construct upload folder
mv UPLOAD UPLOAD2 || true
rm -rf UPLOAD2 || true
mkdir -p UPLOAD/${MACHINE}
export DEST=$(pwd)/UPLOAD/${MACHINE}


cd $REPODIR

cd output

#pwd
#ls -alhR tmp/deploy/images

for board in $(ls $BOARDOUT)
do
	# copy files to $DEST
	. $BOARDOUT/$board/info
	echo "INFO: copy artifact for $x_releng_device/$x_lava_device"
	for i in DEVICE_DTB DEVICE_KERNEL DEVICE_INITRAMFS DEVICE_NBDROOT; do
		eval cp -avL tmp/deploy/images/${TARGETMACHINE}/$(echo "$"${i}) ${DEST}/
	done
done

# for the moment, nothing more use this directory, clean it
rm -r $BOARDOUT

tree $DEST
ls -alhR $DEST

ssh -o StrictHostKeyChecking=no jenkins-slave@10.30.72.8 mkdir -p ${RSYNCDST}

rsync -avr -L -e "ssh -o StrictHostKeyChecking=no" $RSYNCSRC jenkins-slave@10.30.72.8:$RSYNCDST
