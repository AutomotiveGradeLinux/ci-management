#!/usr/bin/env bash
# lib/env.sh – set defaults and normalise all build variables
# Source this first. All variables can be overridden by the caller's environment.
set -euo pipefail

init_env() {
    # ── Machine ────────────────────────────────────────────────────────────────
    export MACHINE="${MACHINE:-qemux86-64}"

    # Map convenience names to Yocto machine names
    case "${MACHINE}" in
        raspberrypi4)    export MACHINE="raspberrypi4-64" ;;
        m3ulcb-nogfx)    export TARGETFEATURES="${TARGETFEATURES:-agl-netboot agl-devel agl-ci}"
                         export MACHINE="m3ulcb" ;;
        h3ulcb-nogfx)    export TARGETFEATURES="${TARGETFEATURES:-agl-netboot agl-devel agl-ci}" ;;
    esac
    export TARGETMACHINE="${MACHINE}"

    # ── Source / branch ────────────────────────────────────────────────────────
    export AGL_BRANCH="${AGL_BRANCH:-master}"
    export AGL_REPO_URL="${AGL_REPO_URL:-https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo}"

    # ── Build targets ──────────────────────────────────────────────────────────
    # AGL_FEATURES is the space-separated list passed to aglsetup.sh
    export AGL_FEATURES="${AGL_FEATURES:-agl-demo agl-devel agl-netboot}"
    export AGL_IMAGE="${AGL_IMAGE:-agl-ivi-demo-flutter}"
    export BUILD_SDK="${BUILD_SDK:-0}"

    # ── Parallelism ────────────────────────────────────────────────────────────
    export BB_NUMBER_THREADS="${BB_NUMBER_THREADS:-$(nproc)}"
    export PARALLEL_MAKE="${PARALLEL_MAKE:--j$(nproc)}"

    # ── Gerrit patch injection (all optional) ──────────────────────────────────
    export GERRIT_PROJECT="${GERRIT_PROJECT:-}"
    export GERRIT_CHANGE_NUMBER="${GERRIT_CHANGE_NUMBER:-}"
    export GERRIT_PATCHSET_NUMBER="${GERRIT_PATCHSET_NUMBER:-}"

    # ── Workspace layout ───────────────────────────────────────────────────────
    export WORKSPACE="${WORKSPACE:-$(pwd)}"
    export SRC_DIR="${WORKSPACE}/src"          # repo clone goes here
    export BUILD_DIR="${SRC_DIR}/output"       # aglsetup.sh -b output
    # Default to container mount points when they exist (Docker usage),
    # otherwise fall back to subdirectories of the workspace (host usage).
    if [[ -z "${DOWNLOADS_DIR:-}" ]]; then
        [[ -d /downloads ]] && DOWNLOADS_DIR=/downloads || DOWNLOADS_DIR="${WORKSPACE}/downloads"
    fi
    if [[ -z "${SSTATE_DIR:-}" ]]; then
        [[ -d /sstate-cache ]] && SSTATE_DIR=/sstate-cache || SSTATE_DIR="${WORKSPACE}/sstate-cache"
    fi
    export DOWNLOADS_DIR SSTATE_DIR

    # ── Skip flags ─────────────────────────────────────────────────────────────
    export SKIP_REPO_SYNC="${SKIP_REPO_SYNC:-0}"

    git config --global user.email "agl-ci-local@example.com" 2>/dev/null || true
    git config --global user.name  "AGL CI Local" 2>/dev/null || true

    echo "=== AGL build config ==="
    echo "  MACHINE          : ${MACHINE}"
    echo "  AGL_BRANCH       : ${AGL_BRANCH}"
    echo "  AGL_FEATURES     : ${AGL_FEATURES}"
    echo "  AGL_IMAGE        : ${AGL_IMAGE}"
    echo "  BB_NUMBER_THREADS: ${BB_NUMBER_THREADS}"
    echo "  SRC_DIR          : ${SRC_DIR}"
    echo "  DOWNLOADS_DIR    : ${DOWNLOADS_DIR}"
    echo "  SSTATE_DIR       : ${SSTATE_DIR}"
    [[ -n "${GERRIT_CHANGE_NUMBER}" ]] && \
        echo "  GERRIT patch     : ${GERRIT_PROJECT} ${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER}"
    echo "========================"
}
