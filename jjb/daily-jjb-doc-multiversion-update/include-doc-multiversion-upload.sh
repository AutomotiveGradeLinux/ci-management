#!/bin/bash
set -e

[[ -z "$WORKSPACE" ]] && WORKSPACE=$(pwd -P)
HTDOCS=${HTDOCS:-$WORKSPACE/htdocs}
TMPDIR=${TMPDIR:-$WORKSPACE/upload-gh}

# publish the docs

mkdir -p $TMPDIR
git clone -b gh-pages git@github.com:automotive-grade-linux/docs-gh-pages.git $TMPDIR/upload-gh-pages
cp -ar $HTDOCS/* $TMPDIR/upload-gh-pages/
pushd $TMPDIR/upload-gh-pages
	git config user.name build.automotivelinux.org
    git config user.email jenkins@automotivelinux.org
    git diff
    git add .
    git commit --amend -m"Render: $(date)"
    git push origin gh-pages:gh-pages -f
popd

