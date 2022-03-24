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
( echo "master marlin jellyfish icefish koi lamprey" | grep -q $TARGETBRANCH ) || exit 0

export TARGETFEATURES="agl-demo agl-devel"
export TARGETQA=""
export TARGETIMAGE="agl-demo-platform-html5"

eval TARGETIMAGE="$TARGETIMAGE"
eval TARGETIMAGEnogfx="$TARGETIMAGE"

#if $DEBUG; then
set | grep ^TARGET || true
set | grep ^GERRIT || true
set | grep ^MACHINE || true
#fi
