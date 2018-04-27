#!/bin/bash

# (c) 2018 Jan-Simon Moeller <jsmoeller@linuxfoundation.org>
# License: GPLv2


ROOTDIR=`pwd`
rm -rf $ROOTDIR/src || true
mkdir -p $ROOTDIR/src/gerrit.automotivelinux.org/gerrit/xds
cd $ROOTDIR/src/gerrit.automotivelinux.org/gerrit/src/xds 
git clone https://gerrit.automotivelinux.org/gerrit/${GERRIT_PROJECT}
cd ${PROJECT_TO_BUILD}
export V=1
make package-all

cd $ROOTDIR
tree

