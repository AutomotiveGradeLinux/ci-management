#!/bin/bash

echo "\n\n\n"
echo "#########################################"
echo "\n\n\n"

kci-publish() {
	# check GERRIT_PROJECT to find if we build an app or not
	if echo $GERRIT_PROJECT |grep -q apps ;then
		# for app
		BUILD_VERSION="AGL-app-gerrit-$GERRIT_CHANGE_NUMBER-$GERRIT_PATCHSET_NUMBER"
	else
		# for release
		BUILD_VERSION="AGL-gerrit-$RELEASE_BRANCH-$RELEASE_VERSION"
	fi

	echo "DEBUG: generate bmeta for kernelCI"
	echo "DEBUG: machine ${TARGETMACHINE}"
	echo "DEBUG: build_version $BUILD_VERSION"
	echo "DEBUG: commit $DIST_BUILD_HASH"
	echo "DEBUG: arch $TARGETARCH"
	echo "DEBUG: branch $GERRIT_BRANCH"
	return 0
	./utils/agl-publish.py --machine ${TARGETMACHINE} \
		--build_version $BUILD_VERSION \
		--commit $DIST_BUILD_HASH \
		--arch $TARGETARCH \
		--branch $GERRIT_BRANCH
}

kci-publish
