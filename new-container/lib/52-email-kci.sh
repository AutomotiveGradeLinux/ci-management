#!/usr/bin/env bash
# lib/52-email-kci.sh – KernelCI email report + build-meta publishing
# Derived from include-agl-send-email-report.sh and
# include-agl-kci-publish-build-meta.sh.
set -euo pipefail

send_email_report() {
    [[ -s build-info ]] || return 0
    # shellcheck disable=SC1091
    source build-info

    [[ -n "${KCI_EMAIL_AUTH_TOKEN:-}" ]] || return 0

    local kci_api='http://kernelci.dev.baylibre.com:8081'
    local tree_name='AGL-yocto'
    local branch="${DIST_BB_AGL_BRANCH:-${TARGETBRANCH}}"
    local git_describe
    if [[ -n "${DIST_BUILD_TOPIC:-}" ]]; then
        git_describe="${DIST_BUILD_TOPIC}"
    else
        git_describe="${DIST_BB_DISTRO_VERSION:-unknown}-${DIST_LAYERS_MD5:0:8}"
    fi

    curl -X POST \
        -H "Authorization: ${KCI_EMAIL_AUTH_TOKEN}" \
        -H "Content-Type: application/json" \
        -d "{\"job\": \"${tree_name}\", \"kernel\": \"${git_describe}\",
             \"git_branch\": \"${branch}\", \"report_type\": \"test\",
             \"plan\": \"agl-testplan\",
             \"send_to\": [\"agl-test-reports@lists.automotivelinux.org\"],
             \"format\": [\"txt\"], \"delay\": 3600}" \
        "${kci_api}/send" || echo "WARNING: send_email_report: curl failed"
    echo "Test email report queued (1 hour delay)"
}

kci_publish() {
    [[ -n "${RELENG:-}" ]] || { echo "WARNING: RELENG not set, skipping kci_publish"; return 0; }

    local build_version kernel_version fsr targetarch

    if echo "${GERRIT_PROJECT:-}" | grep -q apps; then
        build_version="AGL-app-gerrit-${GERRIT_CHANGE_NUMBER:-0}-${GERRIT_PATCHSET_NUMBER:-0}"
        kernel_version="${build_version}"
        fsr="AGL/snapshots/${GERRIT_BRANCH:-master}/latest/${TARGETMACHINE}"
    elif [[ -z "${RELEASE_BRANCH:-}" ]]; then
        build_version="AGL-gerrit-${GERRIT_CHANGE_NUMBER:-0}-${GERRIT_PATCHSET_NUMBER:-0}"
        kernel_version="${DIST_BUILD_TOPIC:-${build_version}}"
        fsr="AGL/upload/ci/${GERRIT_CHANGE_NUMBER:-0}/${GERRIT_PATCHSET_NUMBER:-0}/${TARGETMACHINE}"
    else
        build_version="AGL-gerrit-${RELEASE_BRANCH}-${RELEASE_VERSION}"
        kernel_version="${DIST_BB_DISTRO_VERSION:-${build_version}}"
        fsr="AGL/release/${RELEASE_BRANCH}/${RELEASE_VERSION}/${TARGETMACHINE}"
    fi

    case "${TARGETMACHINE}" in
        bbe|qemuarm)      targetarch=arm ;;
        qemuarm64|raspberrypi4|raspberrypi4-64|h3ulcb-nogfx|h3ulcb) targetarch=arm64 ;;
        qemux86-64)       targetarch=x86_64 ;;
        *)
            echo "WARNING: unknown machine ${TARGETMACHINE}, skipping kci_publish"
            return 0
            ;;
    esac

    set +e
    for api_url in \
        "http://kernelci.dev.baylibre.com:8081/" \
        "https://kernelci.automotivelinux.org:8081/"
    do
        "${RELENG}/utils/agl-publish.py" \
            --machine "${TARGETMACHINE}" \
            --build_version "${build_version}" \
            --commit "${build_version}" \
            --arch "${targetarch}" \
            --fsr "${fsr}" \
            --branch "${GERRIT_BRANCH:-master}" \
            --kernel_version "${kernel_version}" \
            --api "${api_url}" || true
    done
    set -e

    if [[ -e agl-build-meta ]]; then
        find agl-build-meta -type f -exec cat {} \;
    else
        echo "WARNING: no agl-build-meta directory found"
    fi
}
