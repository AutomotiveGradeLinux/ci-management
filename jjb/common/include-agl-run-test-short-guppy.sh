# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

################################################################################
## Run SHORT CI test
################################################################################

set -x

cd $REPODIR
source tmp/deploy/images/${TARGETMACHINE}/build-info

echo "# LAVA lab target: ${LAVA_LAB} #"
# releng-scripts depends on jinja2 >= 2.9
echo "## Check version of python-jinja2: "
pip show jinja2
CREATE_ARGS=""
CREATE_ARGS+="--machine ${releng_device} "
CREATE_ARGS+="--build-type release "
#[[ ! -z $RELEASE_BRANCH ]] && CREATE_ARGS+="--branch $RELEASE_BRANCH "
#[[ ! -z $RELEASE_VERSION ]] && CREATE_ARGS+="--version $RELEASE_VERSION "
CREATE_ARGS+="--url https://download.automotivelinux.org/AGL/upload/ci/${RELEASE_BRANCH}/${RELEASE_VERSION}/${MACHINE}/deploy/images/${TARGETMACHINE}/ "
CREATE_ARGS+="--name AGL-gerrit-$RELEASE_BRANCH-$RELEASE_VERSION "
[[ ! -z $DIST_BB_DISTRO_VERSION ]] && CREATE_ARGS+="--build-version $DIST_BB_DISTRO_VERSION "
[[ ! -z $DIST_BUILD_HASH ]] && CREATE_ARGS+="--commit $DIST_BUILD_HASH "
[[ ! -z $DIST_BUILD_ID ]] && CREATE_ARGS+="--build-id $DIST_BUILD_ID "
[[ ! -z $DIST_BB_AGL_BRANCH ]] && CREATE_ARGS+="--branch $DIST_BB_AGL_BRANCH "
[[ ! -z $DIST_BB_AGLVERSION ]] && CREATE_ARGS+="--version $DIST_BB_AGLVERSION "
CREATE_ARGS+="--callback-from ${LAVA_LAB} "
$RELENG/utils/create-jobs.py ${CREATE_ARGS} > testjob.yaml

if [ $? != 0 ]; then
    echo "ERROR: Machine ${releng_device}: LAVA job creation failed."
    exit 0
else
    cat testjob.yaml
fi
