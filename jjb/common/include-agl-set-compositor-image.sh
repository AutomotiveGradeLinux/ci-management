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
( echo "master jellyfish icefish" | grep -q $TARGETBRANCH ) || exit 0

# Use the agl-compositor
export TARGETFEATURES="agl-demo agl-devel agl-netboot agl-compositor"
export TARGETQA=""
export TARGETIMAGE="agl-demo-platform"

eval TARGETIMAGE="$TARGETIMAGE"
eval TARGETIMAGEnogfx="$TARGETIMAGE"

#if $DEBUG; then
set | grep ^TARGET || true
set | grep ^GERRIT || true
set | grep ^MACHINE || true
#fi
