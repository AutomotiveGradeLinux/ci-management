# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

################################################################################
## Run SHORT CI test
################################################################################

set -x

UPLOAD_URL_BASE=http://download.automotivelinux.org/AGL/upload/ci
UPLOAD_URL=${UPLOAD_URL_BASE}/${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER}/${MACHINE}

cd $REPODIR

wget -q ${UPLOAD_URL}/build-info
if [ -e build-info ]; then
	cat build-info
	source build-info
fi

echo "# LAVA lab target: ${LAVA_LAB} #"
# releng-scripts depends on jinja2 >= 2.9
echo "## Check version of python-jinja2: "
pip show jinja2
CREATE_ARGS=""
CREATE_ARGS+="--machine ${releng_device} "
CREATE_ARGS+="--build-type ci "
[[ ! -z $GERRIT_CHANGE_NUMBER ]] && CREATE_ARGS+="--changeid $GERRIT_CHANGE_NUMBER "
[[ ! -z $GERRIT_PATCHSET_NUMBER ]] && CREATE_ARGS+="--patchset $GERRIT_PATCHSET_NUMBER "
CREATE_ARGS+="--name AGL-gerrit-$GERRIT_CHANGE_NUMBER-$GERRIT_PATCHSET_NUMBER "
if [[ ! -z $DIST_BUILD_TOPIC ]]; then
    CREATE_ARGS+="--build-version $DIST_BUILD_TOPIC "
else
    [[ ! -z $DIST_BB_DISTRO_VERSION ]] && CREATE_ARGS+="--build-version $DIST_BB_DISTRO_VERSION-${DIST_LAYERS_MD5:0:8} "
fi
[[ ! -z $DIST_BUILD_HASH ]] && CREATE_ARGS+="--commit $DIST_BUILD_HASH "
[[ ! -z $DIST_BUILD_ID ]] && CREATE_ARGS+="--build-id $DIST_BUILD_ID "
[[ ! -z $DIST_BB_AGL_BRANCH ]] && CREATE_ARGS+="--branch $DIST_BB_AGL_BRANCH "
[[ ! -z $DIST_BB_AGLVERSION ]] && CREATE_ARGS+="--version $DIST_BB_AGLVERSION "
CREATE_ARGS+="--callback-from ${LAVA_LAB} "
if [[ ! -z $lavacli_tags ]]; then
    CREATE_ARGS+="--device-tags ${lavacli_tags} "
fi
$RELENG/utils/create-jobs.py ${CREATE_ARGS} > testjob.yaml

if [ $? != 0 ]; then
    echo "ERROR: Machine ${releng_device}: LAVA job creation failed."
    exit 0
else
    cat testjob.yaml
fi
