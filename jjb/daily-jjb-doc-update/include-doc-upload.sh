#!/bin/bash

# publish the docs
pushd webdocs-agl
  git clone -b gh-pages git@github.com:automotive-grade-linux/docs-agl.git upload-gh-pages
  cp -ar build-dev/* upload-gh-pages/
  pushd upload-gh-pages
    git config user.name build.automotivelinux.org
    git config user.email jenkins@automotivelinux.org
    git diff
    git add .
    git commit --amend -m"Render: $(date)"
    git push origin gh-pages:gh-pages -f
  popd
popd

