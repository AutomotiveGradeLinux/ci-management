#!/bin/bash
# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2
#
# debugging purposes
set -e

################################################################################
## Header
################################################################################

# only run on master, jellyfish and icefish
! ( echo "marlin jellyfish lamprey koi" | grep -q $TARGETBRANCH ) || exit 0

export TARGETFEATURES="agl-demo agl-devel agl-ci"
export TARGETQA=""
export TARGETIMAGE="agl-ivi-demo-platform-flutter"

eval TARGETIMAGE="$TARGETIMAGE"
eval TARGETIMAGEnogfx="$TARGETIMAGE"

#if $DEBUG; then
set | grep ^TARGET || true
set | grep ^GERRIT || true
set | grep ^MACHINE || true
#fi
