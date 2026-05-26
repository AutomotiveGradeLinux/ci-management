#!/usr/bin/env bash
# lib/bitbake.sh – bitbake build helpers
# Must be called from BUILD_DIR with the bitbake environment already active.
set -euo pipefail

bitbake_image() {
    local target="${1:-${AGL_IMAGE}}"
    echo "=== bitbake ${target} ==="
    # One retry to survive the intermittent tar-native race condition
    bitbake "${target}" || { echo "## retry ##"; sync; sleep 2; bitbake "${target}"; }
    echo "=== build complete ==="
    du -hs tmp/deploy/images/"${MACHINE}"/* 2>/dev/null || true
}

bitbake_sdk() {
    local target="${1:-${AGL_IMAGE}}"
    echo "=== bitbake -c populate_sdk ${target} ==="
    bitbake -c populate_sdk "${target}" || \
        { echo "## retry ##"; sync; sleep 2; bitbake -c populate_sdk "${target}"; }
    echo "=== SDK build complete ==="
    ls -lh tmp/deploy/sdk/*.sh 2>/dev/null || true
}
