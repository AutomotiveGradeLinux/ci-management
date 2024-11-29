#!/bin/bash
# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2
#
# debugging purposes
set -e

################################################################################
## Header
################################################################################

export TARGETFEATURES="agl-ic-container agl-devel agl-ci"
export TARGETQA=""
export TARGETIMAGE="agl-cluster-demo-lxc-host"

#TARGETIMAGE="$TARGETIMAGE"
TARGETIMAGEnogfx="$TARGETIMAGE"

#if $DEBUG; then
set | grep ^TARGET || true
set | grep ^GERRIT || true
set | grep ^MACHINE || true
#fi
