#!/bin/bash
# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2
#
# debugging purposes
set -e

################################################################################
## Header
################################################################################

# Use the agl-compositor
export TARGETFEATURES="agl-demo agl-devel agl-netboot"
export TARGETQA=""
export TARGETIMAGE="agl-ivi-demo-platform"

eval TARGETIMAGE="$TARGETIMAGE"
eval TARGETIMAGEnogfx="$TARGETIMAGE"

#if $DEBUG; then
set | grep ^TARGET || true
set | grep ^GERRIT || true
set | grep ^MACHINE || true
#fi
