#!/bin/bash

echo "\n\n\n"
echo "#########################################"
echo "\n\n\n"

kci-publish() {
	if [ -e tmp/deploy/images/${TARGETMACHINE}/build-info ] ; then
		echo "DEBUG: load build-info"
		# we need some variable from here
		source tmp/deploy/images/${TARGETMACHINE}/build-info
	fi
	echo "DEBUG: GERRIT_PROJECT $GERRIT_PROJECT"

	FSR=""
	# check GERRIT_PROJECT to find if we build an app or not
	if echo $GERRIT_PROJECT |grep -q apps ;then
		# for app
		BUILD_VERSION="AGL-app-gerrit-$GERRIT_CHANGE_NUMBER-$GERRIT_PATCHSET_NUMBER"
		KERNEL_VERSION="$BUILD_VERSION"
		echo "APP: $BUILD_VERSION $KERNEL_VERSION"
		FSR="AGL/snapshots/$GERRIT_BRANCH/latest/$TARGETMACHINE"
	else
		if [ -z "$RELEASE_BRANCH" ];then
			# for CI
			BUILD_VERSION="AGL-gerrit-$GERRIT_CHANGE_NUMBER-$GERRIT_PATCHSET_NUMBER"
			KERNEL_VERSION="$DIST_BUILD_TOPIC"
			echo "CI: $BUILD_VERSION $KERNEL_VERSION"
			FSR="AGL/upload/ci/$GERRIT_CHANGE_NUMBER/$GERRIT_PATCHSET_NUMBER/$TARGETMACHINE"
		else
			# for release
			BUILD_VERSION="AGL-gerrit-$RELEASE_BRANCH-$RELEASE_VERSION"
			KERNEL_VERSION="$DIST_BB_DISTRO_VERSION"
			echo "RELEASE: $BUILD_VERSION $KERNEL_VERSION"
			FSR="AGL/release/$RELEASE_BRANCH/$RELEASE_VERSION/$TARGETMACHINE"
		fi
	fi

	# TARGETARCH exists only in ci-apps
	case $TARGETMACHINE in
	bbe)
		TARGETARCH="arm"
	;;
	qemuarm64)
		TARGETARCH="arm64"
	;;
	qemuarm)
		TARGETARCH="arm"
	;;
	qemux86-64)
		TARGETARCH="x86_64"
	;;
	raspberrypi4)
		TARGETARCH="arm64"
	;;
	raspberrypi4-64)
		TARGETARCH="arm64"
	;;
	h3ulcb-nogfx)
		TARGETARCH="arm64"
	;;
	h3ulcb)
		TARGETARCH="arm64"
	;;
	*)
		echo "ERROR: unknow machine $TARGETMACHINE"
		return 0
	;;
	esac

	echo "DEBUG: generate bmeta for kernelCI"
	echo "DEBUG: machine ${TARGETMACHINE}"
	echo "DEBUG: build_version $BUILD_VERSION"
	echo "DEBUG: commit $DIST_BUILD_HASH"
	echo "DEBUG: arch $TARGETARCH"
	echo "DEBUG: branch $GERRIT_BRANCH"

	$RELENG/utils/agl-publish.py --machine ${TARGETMACHINE} \
		--build_version $BUILD_VERSION \
		--commit $DIST_BUILD_HASH \
		--arch $TARGETARCH \
		--fsr $FSR \
		--branch $GERRIT_BRANCH \
		--kernel_version $KERNEL_VERSION \
		--api http://kernelci.dev.baylibre.com:8081/

	$RELENG/utils/agl-publish.py --machine ${TARGETMACHINE} \
		--build_version $BUILD_VERSION \
		--commit $DIST_BUILD_HASH \
		--arch $TARGETARCH \
		--fsr $FSR \
		--branch $GERRIT_BRANCH \
		--kernel_version $KERNEL_VERSION \
		--api https://kernelci.automotivelinux.org:8081/
	# DEBUG purpose, verify what is uploaded
	if [ -e agl-build-meta ];then
		find agl-build-meta -type f | xargs cat
	else
		echo "ERROR: no agl-build-meta directory"
	fi
	return 0
}

kci-publish
