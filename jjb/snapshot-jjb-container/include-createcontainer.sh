#!/bin/bash

#set -x
set -e
#

git clone https://gerrit.automotivelinux.org/gerrit/AGL/docker-worker-generator
cd docker-worker-generator/

# dump where we are in jenkins log :)
git log -n 1

# add Jenkins BUILD_ID in image version
FULLVER=$(cat VERSION)-${BUILD_ID}

# override VERSION variable when invoking make to build and export docker image
make VERSION=$FULLVER build
make VERSION=$FULLVER export

ls

echo "###########################"

mkdir -p ../container
mv docker_agl_worker*.tar.xz ../container/

# workaround due to SPEC-979
ln -s $(basename ../container/docker_agl_worker*.tar.xz) ../container/docker_agl_worker-latest.tar.xz

ls ../container

echo "###########################"

