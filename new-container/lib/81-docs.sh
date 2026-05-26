#!/usr/bin/env bash
# lib/81-docs.sh – daily AGL docs build and GitHub Pages publish
# Derived from jjb/daily-jjb-doc-update/include-doc-update.sh and
# include-doc-upload.sh.
set -euo pipefail

docs_build() {
    git config --global user.name build.automotivelinux.org
    git config --global user.email jenkins@automotivelinux.org

    rm -rf docs-webtemplate || true
    wget -q https://raw.githubusercontent.com/automotive-grade-linux/docs-webtemplate/master/setupdocs.sh
    mkdir -p docs-webtemplate
    bash -x setupdocs.sh \
        --directory=docs-webtemplate \
        --webtemplate-ref=master \
        --doctools-ref=master
    cd docs-webtemplate
    make build
}

docs_publish() {
    local workspace="${WORKSPACE:-$(pwd)}"
    local htdocs="${HTDOCS:-${workspace}/docs-webtemplate/build-dev/}"
    local tmpdir="${workspace}/upload-gh"

    ssh-keyscan -H github.com >> ~/.ssh/known_hosts 2>/dev/null || true

    rm -rf "${tmpdir}" || true
    mkdir -p "${tmpdir}"
    git clone -b gh-pages \
        git@github.com:automotive-grade-linux/docs-gh-pages.git \
        "${tmpdir}/upload-gh-pages"

    rm -rf "${tmpdir}/upload-gh-pages"/*
    cp -ar "${htdocs}"/* "${tmpdir}/upload-gh-pages/"
    echo "old-docs.automotivelinux.org" > "${tmpdir}/upload-gh-pages/CNAME"

    pushd "${tmpdir}/upload-gh-pages"
        git config user.name build.automotivelinux.org
        git config user.email jenkins@automotivelinux.org
        git diff
        git add .
        git commit --amend -m "Render: $(date)"
        git push origin gh-pages:gh-pages -f
    popd
}
