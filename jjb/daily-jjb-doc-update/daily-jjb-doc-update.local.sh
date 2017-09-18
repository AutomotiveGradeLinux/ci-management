#!/bin/bash

#rm -rf docs-agl || true
# cloning git@github.com:automotive-grade-linux/docs-agl.git

if test -d docs-agl; then
    pushd docs-agl
	git remote -v update
	git reset --hard origin/master
    popd
else
    git clone git@github.com:automotive-grade-linux/docs-agl.git
fi

pushd docs-agl

    . ../include-doc-update.sh

    pushd webdocs-agl

        ( sleep 7 ; firefox http://127.0.0.1:4000 ) &
	make serve

    popd


popd