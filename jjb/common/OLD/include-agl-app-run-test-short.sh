# (c) 2019 Corentin Labbe clabbe(at)baylibre.com
# License GPLv2
# Copied from jjb/common/include-agl-run-test-short.sh

################################################################################
## Run SHORT CI test
################################################################################

#set -x

cd $REPODIR

BUILD_VERSION="AGL-app-gerrit-$GERRIT_CHANGE_NUMBER-$GERRIT_PATCHSET_NUMBER"
[[ -e output/repo-manifest-r.txt.sha1 ]] && BUILD_VERSION+="-$(cat output/repo-manifest-r.txt.sha1)"

echo "# LAVA lab target: ${LAVA_LAB} #"
# releng-scripts depends on jinja2 >= 2.9
echo "## Check version of python-jinja2: "
pip show jinja2
CREATE_ARGS=""
case $TARGETARCH in
arm)
CREATE_ARGS+="--machine qemuarm "
;;
x86-64)
CREATE_ARGS+="--machine qemux86-64 "
;;
aarch64)
CREATE_ARGS+="--machine qemuarm64 "
;;
*)
	echo "ERROR: unknown architecture $TARGETARCH"
	exit 1
;;
esac
CREATE_ARGS+="--build-type snapshot --branch master --version latest "
[[ ! -z $GERRIT_CHANGE_NUMBER ]] && CREATE_ARGS+="--app-changeid $GERRIT_CHANGE_NUMBER "
[[ ! -z $GERRIT_PATCHSET_NUMBER ]] && CREATE_ARGS+="--app-patchset $GERRIT_PATCHSET_NUMBER "
[[ ! -z $AGLBRANCH ]] && CREATE_ARGS+="--app-branch $AGLBRANCH "
CREATE_ARGS+="--name AGL-gerrit-$GERRIT_CHANGE_NUMBER-$GERRIT_PATCHSET_NUMBER "
CREATE_ARGS+="--build-version $BUILD_VERSION "
CREATE_ARGS+="--callback-from ${LAVA_LAB} "
CREATE_ARGS+="--test application-lifecycle pyagl"

echo "DEBUG: call create-jobs.py with $CREATE_ARGS"
$RELENG/utils/create-jobs.py ${CREATE_ARGS} > testjob.yaml

if [ $? != 0 ]; then
    echo "ERROR: Machine ${releng_device}: LAVA job creation failed."
    exit 0
else
    cat testjob.yaml
fi
