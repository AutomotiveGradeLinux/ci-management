#!/bin/bash

#set -x
export AGLBRANCH=master
export GERRIT_REFSPEC="refs/changes/51/9551/2"
export GERRIT_PROJECT="apps/mediaplayer"
export GERRIT_CHANGE_NUMBER="10799"
export GERRIT_PATCHSET_NUMBER="1"
export GERRIT_PATCHSET_REVISION="1a1ff962da92aff5a1d3e757710c725e03238458"
export GERRIT_HOST="gerrit.automotivelinux.org"
export GERRIT_PORT="29418"

export -p > env.save

THISPWD=$(pwd)
for TARGETARCH in aarch64 arm x86-64; do
pushd $THISPWD

for i in `compgen -e | grep -v ^PATH`; do
    unset $i
done

source env.save

rm -rf ~/agl-sdk || true

. ../common/include-apps-header.sh
. ../common/include-apps-fetch-install-sdk.sh
. ../common/include-apps-build-app.sh
. ../common/include-apps-prepare-upload-folder.sh
# do not really upload
#. ../common/include-apps-rsync-download-changeid.sh

popd

ls -R UPLOAD

done