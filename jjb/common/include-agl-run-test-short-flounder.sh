# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

################################################################################
## Run SHORT CI test
################################################################################

#set -x

cd $REPODIR

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
BUILD_VERSION="AGL-gerrit-$RELEASE_BRANCH-$RELEASE_VERSION"
[[ -e output/repo-manifest-r.txt.sha1 ]] && BUILD_VERSION+="-$(cat output/repo-manifest-r.txt.sha1)"
CREATE_ARGS+="--name AGL-gerrit-$RELEASE_BRANCH-$RELEASE_VERSION "
CREATE_ARGS+="--build-version $BUILD_VERSION "
CREATE_ARGS+="--callback-from ${LAVA_LAB} "
$RELENG/utils/create-jobs.py ${CREATE_ARGS} > testjob.yaml

if [ $? != 0 ]; then
    echo "ERROR: Machine ${releng_device}: LAVA job creation failed."
    exit 0
else
    cat testjob.yaml
fi
