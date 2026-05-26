#!/usr/bin/env bash
# lib/80-prefetch.sh – weekly AGL download-mirror pre-fetch
# Derived from jjb/pre-fetch/include-prefetch.sh and include-rsync-prefetch.sh.
set -euo pipefail

prefetch_run() {
    local boards="${BOARDS:-qemux86-64 qemuarm qemuarm64 raspberrypi4 raspberrypi5 h3ulcb-nogfx}"
    local features="agl-demo agl-devel agl-netboot agl-ci"
    local features_nogfx="agl-netboot agl-devel agl-ci"
    local target_image="agl-ivi-demo-qt agl-ivi-demo-flutter"
    local target_image_nogfx="agl-image-minimal"

    mkdir -p mirror sstate

    # Remove previous clone to keep disk usage bounded
    mv repoclone repoclone2 > /dev/null 2>&1 || true
    rm -rf repoclone2 || true
    mkdir -p repoclone
    cd repoclone

    local ref_opt=""
    [[ -d /opt/AGL/preclone ]] && ref_opt="--reference=/opt/AGL/preclone"

    repo init ${ref_opt} \
        -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo.git
    repo sync -j8

    external/poky/scripts/install-buildtools
    # shellcheck disable=SC1091
    source external/poky/buildtools/environment-setup-x86_64-pokysdk-linux

    for board in ${boards}; do
        pushd .
        local cur_features="${features}"
        local cur_image="${target_image}"
        case "${board}" in
            m3ulcb-nogfx|h3ulcb-nogfx)
                cur_features="${features_nogfx}"
                cur_image="${target_image_nogfx}"
                ;;
        esac
        source meta-agl/scripts/aglsetup.sh -m "${board}" -b "build-${board}" ${cur_features}
        ln -sf ../../mirror downloads
        ln -sf ../../sstate sstate-cache
        echo 'BB_GENERATE_MIRROR_TARBALLS = "1"' >> conf/local.conf
        bitbake --runall=fetch ${cur_image} -k || true
        popd
    done

    # Clean up partial downloads that bitbake marks done
    pushd ../mirror
        rm -f *.done || true
        find . -maxdepth 1 -type d | grep -v uninative | xargs rm -rf 2>/dev/null || true
        rm -f *bad-checksum* || true
        ls -alh
    popd
}

prefetch_publish() {
    local rsyncsrc="${WORKSPACE:-$(pwd)}/mirror/"
    local rsyncdst="${ARTIFACT_HOST:-jenkins-slave@10.30.72.8}:/srv/download/AGL/mirror/"
    rsync -avr -e ssh "${rsyncsrc}" "${rsyncdst}"
}
