# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

################################################################################
## Run SHORT CI test
################################################################################
#set -x

cd $REPODIR

# clone repo for templates and related utils, add to $PATH for later use
if [ ! -e releng-scripts ]; then
    git clone --branch $TARGETBRANCH https://git.automotivelinux.org/AGL/releng-scripts
else
    (cd releng-scripts; git remote update; git checkout -f origin/$TARGETBRANCH)
fi

if [ -e releng-scripts/utils ]; then
    export PATH=$PATH:$PWD/releng-scripts/utils
    RELENG=$PWD/releng-scripts
fi

# WARNING: we need gen_info in last, the device of the current JENKINS CIBT
# example: for x86, the JENKINS CIBT job is for "qemu" and produce artifacts for all x86 boards.
# so we need to gen_info for qemux86 and upsquare, this content will be used to copy artifacts just after.
# but the LAVA job need to be generated only for qemu. So we need to have lava_device and releng_device for it.
export BOARDOUT=$(mktemp --directory)
case $MACHINE in
qemux86-64)
	lava_device=upsquare
	releng_device=upsquare
	gen_info || exit 0
	lava_device=qemu
	releng_device=qemux86-64
	gen_info || exit 0
;;
raspberrypi4)
	lava_device=bcm2711-rpi-4-b
	releng_device=raspberrypi4
	gen_info || exit 0
;;
qemuarm)
	lava_device=qemu
	releng_device=qemuarm
	gen_info || exit 0
;;
qemuarm64)
	lava_device=qemu
	releng_device=qemuarm64
	gen_info || exit 0
;;
h3ulcb-nogfx)
	lava_device=r8a7795-h3ulcb-kf
	releng_device=h3ulcb-kf
	gen_info || exit 0
;;
upsquare)
	lava_device=upsquare
	releng_device=upsquare
	# NO gen_info since, we use artifacts of the qemux86_64 CIBT
;;
*)
	echo "ERROR: unknown machine $MACHINE"
	exit 0
;;
esac

#gen board info in $BOARDOUT
gen_info() {
	if [ -z "${lava_device}" -o -z "${releng_device}" ]; then
		echo "Board not supported: $MACHINE"
		return 1
	fi

	CREATE_ARGS=""
	CREATE_ARGS+="--machine ${releng_device} "

	if [[ $TARGETBRANCH ]] && [[ x"master" != x"$TARGETBRANCH" ]] ; then
		CREATE_ARGS+="--branch $TARGETBRANCH "
	fi

	# If it's a release build
	if [[ $RELEASE_BRANCH ]] && [[ $RELEASE_VERSION ]]; then
		CREATE_ARGS+="--build-type release $RELEASE_BRANCH $RELEASE_VERSION "
	fi
	# If it's a CI build
	if [[ $GERRIT_CHANGE_NUMBER ]] && [[ $GERRIT_PATCHSET_NUMBER ]]; then
		CREATE_ARGS+="--build-type ci $GERRIT_CHANGE_NUMBER $GERRIT_PATCHSET_NUMBER "
	fi

	$RELENG/utils/job-prereq.py ${CREATE_ARGS}
	if [ $? -ne 0 ]; then
		echo "Board not supported by releng-scripts: job-prereq.py"
		return 1
	fi
	# First call to job-prereq suceeded, other should suceed as they use the same args.
	export DEVICE_DTB=`$RELENG/utils/job-prereq.py ${CREATE_ARGS} --dtb`
	export DEVICE_KERNEL=`$RELENG/utils/job-prereq.py ${CREATE_ARGS} --kernel`
	export DEVICE_INITRAMFS=`$RELENG/utils/job-prereq.py ${CREATE_ARGS} --initrd`
	export DEVICE_NBDROOT=`$RELENG/utils/job-prereq.py ${CREATE_ARGS} --nbdroot`
	# thoses variables (DEVICE_DTB DEVICE_KERNEL DEVICE_INITRAMFS DEVICE_NBDROOT) are only used for copying artifacts later

	mkdir -p $BOARDOUT/
	# We use both lava_device and releng_device for handling name collision (like qemu)
	BDIRNAME="$lava_device-$releng_device"
	echo "DEVICE_DTB=$DEVICE_DTB" > $BOARDOUT/$BDIRNAME/info
	echo "DEVICE_KERNEL=$DEVICE_KERNEL" >> $BOARDOUT/$BDIRNAME/info
	echo "DEVICE_INITRAMFS=$DEVICE_INITRAMFS" >> $BOARDOUT/$BDIRNAME/info
	echo "DEVICE_NBDROOT=$DEVICE_NBDROOT" >> $BOARDOUT/$BDIRNAME/info
	# thoses two variable are only for debugging
	echo "x_releng_device=$releng_device" >> $BOARDOUT/$BDIRNAME/info
	echo "x_lava_device=$lava_device" >> $BOARDOUT/$BDIRNAME/info
	return 0
}

# echo NEXT is rsync
#exit 0
