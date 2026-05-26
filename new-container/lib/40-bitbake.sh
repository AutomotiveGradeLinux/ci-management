#!/usr/bin/env bash
# lib/40-bitbake.sh – bitbake invocation helpers
# Derived from include-agl-bitbake-image.sh, -nofail, -sdk, -sdk-x64only,
# and include-agl-setup-and-bitbake-ivi-image.sh (which was a no-op body).
# Must be called from inside REPODIR/output (the bitbake build dir).
set -euo pipefail

bitbake_image() {
    local targets="${1:-${TARGETIMAGE}}"
    echo "=== bitbake_image: ${targets} ==="
    cat conf/local.conf
    # Single retry to catch intermittent tar-native failures (SPEC-*)
    ( bitbake ${targets} ) || \
    ( echo '## Failed once, retry ##'; sync; sleep 2; bitbake -v -v ${targets} ) || \
    ( echo '## Failed again, bail out'; exit 1 )
    du -hs tmp/deploy/*
}

bitbake_image_nofail() {
    local targets="${1:-${TARGETIMAGE}}"
    echo "=== bitbake_image_nofail: ${targets} ==="
    bitbake ${targets} || true
    du -hs tmp/deploy/* 2>/dev/null || true
}

bitbake_sdk() {
    local targets="${1:-${TARGETSDKIMAGE}}"
    echo "=== bitbake_sdk: ${targets} ==="
    ( bitbake ${targets} ) || \
    ( echo '## Failed once, retry ##'; sync; sleep 2; bitbake ${targets} ) || \
    ( echo '## Failed again, bail out'; exit 1 )
    du -hs tmp/deploy/*
}

bitbake_sdk_x64only() {
    # Build SDK only for x86-64 targets; silently skip everything else.
    if [[ "${TARGETMACHINE}" == "qemux86-64" ]]; then
        bitbake_sdk "${@:-}"
    else
        echo "=== bitbake_sdk_x64only: skipping for TARGETMACHINE=${TARGETMACHINE} ==="
    fi
}

bitbake_ycl() {
    # yocto-check-layer CI run
    echo "=== bitbake_ycl ==="
    # install-buildtools already run by run_aglsetup; ensure env is active
    pushd "$(dirname "$(pwd)")/.."   # back to REPODIR
        external/poky/scripts/install-buildtools
        # shellcheck disable=SC1090
        source external/poky/buildtools/environment-setup-x86_64-pokysdk-linux

        pushd meta-agl
            if [[ -x scripts/ci-yocto-check-layer.sh ]]; then
                ./scripts/ci-yocto-check-layer.sh
            fi
        popd

        pushd meta-agl-demo
            if [[ -x scripts/ci-yocto-check-layer.sh ]]; then
                ./scripts/ci-yocto-check-layer.sh
            fi
        popd
    popd
}
