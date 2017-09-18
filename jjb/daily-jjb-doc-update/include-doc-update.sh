#!/bin/bash
set -e 

# we need a name and an email
#git config --global user.name build.automotivelinux.org
#git config --global user.email jenkins@automotivelinux.org
git config user.name build.automotivelinux.org
git config user.email jenkins@automotivelinux.org

# make sure 'node' is in path (debian calls it nodejs)
mkdir -p bin
ln -sf /usr/bin/nodejs bin/node
export PATH=$PATH:`pwd`/bin

pushd doctools/webdocs
  npm install
  gem list
popd

# build the docs
pushd webdocs-agl
  make clean
  make fetch
  make build
popd