#!/usr/bin/env bash
# lib/70-container.sh – AGL Docker worker container build and publish
# Derived from jjb/snapshot-jjb-container/include-createcontainer.sh
# and include-rsync-container.sh.
set -euo pipefail

container_build() {
    git clone https://gerrit.automotivelinux.org/gerrit/AGL/docker-worker-generator
    pushd docker-worker-generator
        git log -n 1
        local base_ver
        base_ver=$(cat VERSION)
        local full_ver="${base_ver}-${BUILD_ID:-$(date +%Y%m%d%H%M%S)}"
        make VERSION="${full_ver}" build
        make VERSION="${full_ver}" export
        ls -l
    popd

    mkdir -p container
    mv docker-worker-generator/docker_agl_worker*.tar.xz container/
    # Convenience symlink for downstream consumers that expect -latest
    pushd container
        local archive
        archive=$(ls docker_agl_worker*.tar.xz | head -1)
        ln -sf "${archive}" docker_agl_worker-latest.tar.xz
    popd
    ls -l container/
}

container_publish() {
    local rsyncsrc="${WORKSPACE:-$(pwd)}/container/"
    local rsyncdst="${ARTIFACT_HOST:-jenkins-slave@10.30.72.8}:/srv/download/AGL/snapshots/sdk/docker/"
    rsync -avr -e ssh "${rsyncsrc}" "${rsyncdst}"
}
