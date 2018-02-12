# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

################################################################################
## Run SHORT CI test
################################################################################
set -x

#ls -alh
#pwd
#set

cd $REPODIR

# clone repo for templates and related utils, add to $PATH for later use
if [ ! -e releng-scripts ]; then
    git clone --branch release https://git.automotivelinux.org/AGL/releng-scripts
else
    (cd releng-scripts; git remote update; git checkout -f origin/release)
fi

if [ -e releng-scripts/utils ]; then
    export PATH=$PATH:$PWD/releng-scripts/utils
    RELENG=$PWD/releng-scripts
fi

declare -A agl_lava_releng_aliases
agl_lava_releng_aliases=(
    [raspberrypi3]="raspberrypi3-uboot;raspberrypi3"
    [qemux86-64]="qemu;qemux86-64"
    [m3ulcb-nogfx]="r8a7796-m3ulcb;m3ulcb"
    [porter-nogfx]="renesas-porter;porter"
    [dra7xx-evm]="dra7-evm;dra7xx-evm"
)

OFS=${IFS}
IFS=';'
arr=(${agl_lava_releng_aliases[$MACHINE]})
IFS=${OFS}
lava_device=${arr[0]}
releng_device=${arr[1]}
# And agl_device=${MACHINE}

if [ -z "${lava_device}" -o -z "${releng_device}" ]; then
    echo "Board not supported: $MACHINE"
    exit 0
fi

CREATE_ARGS=""
CREATE_ARGS+="--machine ${releng_device} "

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
    exit 0
fi
# First call to job-prereq suceeded, other should suceed as they use the same args.
export DEVICE_DTB=`$RELENG/utils/job-prereq.py ${CREATE_ARGS} --dtb`
export DEVICE_KERNEL=`$RELENG/utils/job-prereq.py ${CREATE_ARGS} --kernel`
export DEVICE_INITRAMFS=`$RELENG/utils/job-prereq.py ${CREATE_ARGS} --initrd`
export DEVICE_NBDROOT=`$RELENG/utils/job-prereq.py ${CREATE_ARGS} --nbdroot`

# echo NEXT is rsync
#exit 0
