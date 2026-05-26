#!/usr/bin/env bash
# lib/30-aglsetup.sh – install-buildtools, aglsetup, sstate/downloads linking
# Derived from jjb/common/include-agl-source-aglsetup.sh
set -euo pipefail

run_aglsetup() {
    # Must be called from REPODIR

    external/poky/scripts/install-buildtools
    # shellcheck disable=SC1090
    source external/poky/buildtools/environment-setup-x86_64-pokysdk-linux

    # Detect aglsetup topic-support version
    local AGLSETUP_VERSION
    AGLSETUP_VERSION=$(source meta-agl/scripts/aglsetup.sh --version 2>/dev/null \
        | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "1.0.0")

    local SETUP_OPTS=""
    local TOPIC_SUPPORT_VER="1.2.0"
    if [[ "$(printf '%s\n' "$AGLSETUP_VERSION" "$TOPIC_SUPPORT_VER" | sort -V | head -1)" \
          == "$TOPIC_SUPPORT_VER" ]]; then
        SETUP_OPTS="--topic change-${GERRIT_CHANGE_NUMBER:-0}-${GERRIT_PATCHSET_NUMBER:-0}"
    fi

    # shellcheck disable=SC1090
    source meta-agl/scripts/aglsetup.sh ${SETUP_OPTS} -m "${MACHINE}" -b output ${TARGETFEATURES}

    # Link shared downloads/sstate from NFS tank if present, or use local dirs
    if [[ -d /mnt/tank ]]; then
        rm -rf downloads sstate-cache || true
        ln -sf /mnt/tank/downloads downloads
        ln -sf /mnt/tank/sstate-mirror ../sstate-mirror
        cat > conf/auto.conf << EOF
SSTATE_DIR = "\${TOPDIR}/../sstate-mirror/\${AGL_BRANCH}/\${DEFAULTTUNE}/"
EOF
    else
        ln -sf ../../downloads
        ln -sf ../../sstate-cache
    fi

    echo "" >> conf/local.conf
    echo "### ADDED BY AUTOBUILDER ###" >> conf/local.conf
    echo "" >> conf/local.conf

    # Save pre-build env snapshot for artifact traceability
    local manifest_r="repo-manifest-r.txt"
    repo manifest -r > "${manifest_r}"
    sha1sum "${manifest_r}" | awk '{print $1}' > "${manifest_r}.sha1"

    cat > pre-build-env.txt << EOF
TARGETBRANCH=${TARGETBRANCH}
TARGETIMAGE=${TARGETIMAGE}
TARGETFEATURES=${TARGETFEATURES}
TARGETMACHINE=${TARGETMACHINE}
TARGETPROJECT=${TARGETPROJECT}
MACHINE=${MACHINE}
GERRIT_CHANGE_NUMBER=${GERRIT_CHANGE_NUMBER:-}
GERRIT_PATCHSET_NUMBER=${GERRIT_PATCHSET_NUMBER:-}
EOF

    echo "=== aglsetup complete. AGL_BRANCH=${AGL_BRANCH:-<not set>} ==="
}
