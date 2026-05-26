#!/usr/bin/env bash
# lib/50-publish.sh – rsync artifact publishing helpers
# Derived from include-agl-run-test-rsync-changeid.sh,
# include-agl-run-test-rsync-release.sh,
# include-release-jjb-snapshot-rsync.sh,
# include-agl-remove-artifacts-changeid.sh.
set -euo pipefail

ARTIFACT_HOST="${ARTIFACT_HOST:-jenkins-slave@10.30.72.8}"
ARTIFACT_BASE="${ARTIFACT_BASE:-/srv/download/AGL}"

# Copy LAVA-relevant artifacts from bitbake deploy into UPLOAD/<MACHINE>/
# and rsync to the artifact server.
# Call from REPODIR after run_test_prepare has populated BOARDOUT.
publish_changeid() {
    local rsyncdst="${ARTIFACT_BASE}/upload/ci/${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER}"
    local rsyncsrc
    rsyncsrc="$(pwd)/UPLOAD/"

    # Reset UPLOAD dir
    mv UPLOAD UPLOAD2 2>/dev/null || true
    rm -rf UPLOAD2 2>/dev/null || true
    mkdir -p UPLOAD/"${MACHINE}"
    local dest="$(pwd)/UPLOAD/${MACHINE}"

    cd "${REPODIR}/output"
    echo "=== publish_changeid: collecting artifacts from tmp/deploy/images/${TARGETMACHINE}/ ==="
    ls -alhR tmp/deploy/images

    for board in $(ls "${BOARDOUT}"); do
        # shellcheck disable=SC1090
        source "${BOARDOUT}/${board}/info"
        echo "INFO: collecting for ${x_releng_device}/${x_lava_device}"

        # Workaround SPEC-3751: regenerate missing .xz
        local f_nbdroot="tmp/deploy/images/${TARGETMACHINE}/${DEVICE_NBDROOT}"
        if [[ -n "${DEVICE_NBDROOT:-}" && ! -e "${f_nbdroot}" ]]; then
            local noxz="${f_nbdroot%.xz}"
            if [[ -e "${noxz}" ]]; then
                echo "DEBUG: recompressing ${noxz}"
                xz --threads=0 --stdout "${noxz}" > "${f_nbdroot}"
            else
                echo "ERROR: SPEC-3751: ${noxz} missing too"
            fi
        fi

        for var in DEVICE_DTB DEVICE_KERNEL DEVICE_INITRAMFS DEVICE_NBDROOT; do
            local file="${!var:-}"
            if [[ -n "${file}" && -e "tmp/deploy/images/${TARGETMACHINE}/${file}" ]]; then
                cp -avL "tmp/deploy/images/${TARGETMACHINE}/${file}" "${dest}/"
            fi
        done
    done

    rm -rf "${BOARDOUT}"
    tree "${dest}" 2>/dev/null || ls -alhR "${dest}"

    ssh "${ARTIFACT_HOST}" mkdir -p "${rsyncdst}"
    rsync -avr -L -e ssh "${rsyncsrc}" "${ARTIFACT_HOST}:${rsyncdst}"
}

# Same artifact collection but destinations use RELEASE_BRANCH/RELEASE_VERSION path.
publish_release() {
    local rsyncdst="${ARTIFACT_BASE}/upload/ci/${RELEASE_BRANCH}/${RELEASE_VERSION}"
    local rsyncsrc
    rsyncsrc="$(pwd)/UPLOAD/"

    mv UPLOAD UPLOAD2 2>/dev/null || true
    rm -rf UPLOAD2 2>/dev/null || true
    mkdir -p UPLOAD/"${MACHINE}"
    local dest="$(pwd)/UPLOAD/${MACHINE}"

    cd "${REPODIR}/output"

    for board in $(ls "${BOARDOUT}"); do
        # shellcheck disable=SC1090
        source "${BOARDOUT}/${board}/info"

        local f_nbdroot="tmp/deploy/images/${TARGETMACHINE}/${DEVICE_NBDROOT}"
        if [[ -n "${DEVICE_NBDROOT:-}" && ! -e "${f_nbdroot}" ]]; then
            local noxz="${f_nbdroot%.xz}"
            if [[ -e "${noxz}" ]]; then
                xz --threads=0 --stdout "${noxz}" > "${f_nbdroot}"
            fi
        fi

        for var in DEVICE_DTB DEVICE_KERNEL DEVICE_INITRAMFS DEVICE_NBDROOT; do
            local file="${!var:-}"
            if [[ -n "${file}" && -e "tmp/deploy/images/${TARGETMACHINE}/${file}" ]]; then
                cp -avL "tmp/deploy/images/${TARGETMACHINE}/${file}" "${dest}/"
            fi
        done
    done

    rm -rf "${BOARDOUT}"
    tree "${dest}" 2>/dev/null || ls -alhR "${dest}"

    ssh "${ARTIFACT_HOST}" mkdir -p "${rsyncdst}"
    rsync -avr -L -e ssh "${rsyncsrc}" "${ARTIFACT_HOST}:${rsyncdst}"
}

# Rsync snapshot release artifacts (full deploy tree, not just LAVA files).
publish_snapshot() {
    local snapshot_dst="${ARTIFACT_BASE}/snapshots/${RELEASE_BRANCH}/${RELEASE_VERSION}"
    local deploy_dir="${REPODIR}/output/tmp/deploy"

    ssh "${ARTIFACT_HOST}" mkdir -p "${snapshot_dst}/${MACHINE}"
    rsync -avr -L -e ssh "${deploy_dir}/" "${ARTIFACT_HOST}:${snapshot_dst}/${MACHINE}/"
}

# Remove all CI artifacts for a given gerrit change from the artifact server.
remove_changeid_artifacts() {
    local dst="${ARTIFACT_BASE}/upload/ci/${GERRIT_CHANGE_NUMBER}"
    echo "=== removing ${ARTIFACT_HOST}:${dst} ==="
    ssh "${ARTIFACT_HOST}" rm -rf "${dst}"
}
