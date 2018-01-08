#!/bin/bash

#set -x
set -e
#

git clone https://gerrit.automotivelinux.org/gerrit/AGL/docker-worker-generator
cd docker-worker-generator/

# dump where we are in jenkins log :)
git log -n 1

make build
make export

ls

echo "###########################"

mkdir -p ../container
mv docker_agl_worker*.tar.xz ../container/
ln -s $(basename ../container/docker_agl_worker*.tar.xz) ../container/docker_agl_worker-latest.tar.xz

ls ../container

echo "###########################"

