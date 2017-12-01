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

CREATE_ARGS=""
CREATE_ARGS+="--machine ${MACHINE} "

# If ii's a release build
if [[ ! -z $RELEASE_BRANCH ]] && [[ ! -z $RELEASE_VERSION ]]; then
    CREATE_ARGS+="--build-type {release,$RELEASE_BRANCH,$RELEASE_VERSION} "
fi
# If it's a CI build
if [[ ! -z $GERRIT_CHANGE_NUMBER ]] && [[ ! -z $GERRIT_PATCHSET_NUMBER ]]; then
    CREATE_ARGS+="--build-type {ci,$GERRIT_CHANGE_NUMBER,$GERRIT_PATCHSET_NUMBER} "
fi

export DEVICE_DTB=`$RELENG/utils/job-prereq.py ${CREATE_ARGS} --dtb`
export DEVICE_KERNEL=`$RELENG/utils/job-prereq.py ${CREATE_ARGS} --kernel`
export DEVICE_INITRAMFS=`$RELENG/utils/job-prereq.py ${CREATE_ARGS} --initrd`
export DEVICE_NBDROOT=`$RELENG/utils/job-prereq.py ${CREATE_ARGS} --nbdroot`

# echo NEXT is rsync
#exit 0
