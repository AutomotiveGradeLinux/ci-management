#!/bin/bash

#set -x
set -e

echo "\n\n\n"
echo "#########################################"
echo "\n\n\n"


export RSYNCDST="/srv/download/AGL/upload/ci/${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER}"
export RSYNCSRC=$(pwd)/UPLOAD/

# construct upload folder
mv UPLOAD UPLOAD2 || true
rm -rf UPLOAD2 || true
mkdir -p UPLOAD/${MACHINE}
export DEST=$(pwd)/UPLOAD/${MACHINE}

cd $REPODIR

cd output

pwd
ls -alhR tmp/deploy/images

#set -x

for board in $(ls $BOARDOUT)
do
	. $BOARDOUT/$board/info
	echo "INFO: copy artifact for $x_releng_device/$x_lava_device"
	echo "tmp/deploy/images/${TARGETMACHINE}/${DEVICE_DTB}"
	echo "tmp/deploy/images/${TARGETMACHINE}/${DEVICE_DTB#"$DEVICE_KERNEL"-}"

#	if [ -e tmp/deploy/images/${TARGETMACHINE}/build-info ] ; then
#		cp -avL tmp/deploy/images/${TARGETMACHINE}/build-info ${DEST}/
#	fi

set

	# detect BUG SPEC-3751
	F_NBDROOT="tmp/deploy/images/${TARGETMACHINE}/$DEVICE_NBDROOT"
	if [ ! -e "$F_NBDROOT" ];then
		NOXZ=$(echo "$F_NBDROOT" | sed 's,.xz$,,')
		if [ ! -e "$NOXZ" ];then
			echo "ERROR: cannot recovery from SPEC-3751, $NOXZ does not exists"
		else
			echo "DEBUG: xz $NOXZ to $F_NBDROOT"
			xz --threads=0 --stdout "$NOXZ" > "$F_NBDROOT"
		fi
	fi

	# copy files to $DEST (only if variable is non-empty)
	for i in DEVICE_DTB DEVICE_KERNEL DEVICE_INITRAMFS DEVICE_NBDROOT; do
		FILE=$(eval echo \$${i})
		if [ -n "$FILE" ]; then
			cp -avL tmp/deploy/images/${TARGETMACHINE}/${FILE} ${DEST}/
		fi
	done
done
set +x

# for the moment, nothing more use this directory, clean it
rm -r $BOARDOUT

tree $DEST
ls -alhR $DEST

ssh -o StrictHostKeyChecking=no jenkins-slave@10.30.72.8 mkdir -p ${RSYNCDST}

rsync -avr -L -e "ssh -o StrictHostKeyChecking=no" $RSYNCSRC jenkins-slave@10.30.72.8:$RSYNCDST

