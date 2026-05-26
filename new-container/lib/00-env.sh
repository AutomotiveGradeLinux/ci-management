#!/usr/bin/env bash
# lib/00-env.sh – GERRIT / MACHINE / TARGET* normalisation
# Derived from jjb/common/include-agl-header.sh
# Source this file, then call: init_env [options]
set -euo pipefail

init_env() {
    # Defaults
    export NOGFX="${NOGFX:-false}"
    export VERBOSE="${VERBOSE:-false}"
    export DEBUG="${DEBUG:-false}"

    export TARGETPROJECT="${GERRIT_PROJECT:-AGL/AGL-repo}"
    export TARGETBRANCH="${GERRIT_BRANCH:-master}"
    export TARGETREFSPEC="${GERRIT_REFSPEC:-refs/heads/master}"

    export TARGETFEATURES="${TARGETFEATURES:-agl-ci-change-features agl-ci}"
    export TARGETFEATURESnogfx="${TARGETFEATURESnogfx:-agl-ci-change-features-nogfx agl-ci}"

    export TARGETIMAGE="${TARGETIMAGE:-agl-ivi-demo-qt agl-ivi-demo-flutter}"
    export TARGETIMAGEnogfx="${TARGETIMAGEnogfx:-agl-ivi-demo-qt agl-ivi-demo-flutter}"
    export TARGETSDKIMAGE="${TARGETSDKIMAGE:-agl-ivi-demo-qt agl-ivi-demo-flutter}"

    export MACHINE="${MACHINE:-qemux86-64}"

    # Parse optional flags matching the original header CLI interface
    local OPTIND=1
    while getopts ":b:i:p:r:dnqvx" opt; do
        case "$opt" in
            b) export TARGETBRANCH="$OPTARG" ;;
            i) export TARGETIMAGE="$OPTARG" ;;
            n) export NOGFX=true ;;
            p) export TARGETPROJECT="$OPTARG" ;;
            q) export TARGETQA="-qa" ;;
            r) export TARGETREFSPEC="$OPTARG" ;;
            v) export VERBOSE=true ;;
            x) set -x ;;
            d) export DEBUG=true ;;
            *) ;;
        esac
    done

    export TARGETMACHINE="${MACHINE}"

    # BUILDONLY: skip non-matching machines
    if [[ -n "${BUILDONLY:-}" && "${BUILDONLY}" != "ignore" && "${MACHINE}" != "${BUILDONLY}" ]]; then
        echo "Skipping ${MACHINE} as BUILDONLY is ${BUILDONLY}."
        exit 0
    fi

    # Machine-specific overrides
    case "${MACHINE}" in
        m3ulcb-nogfx)
            export TARGETFEATURES="${TARGETFEATURESnogfx}"
            export TARGETMACHINE="m3ulcb"
            ;;
        h3ulcb-nogfx)
            export TARGETFEATURES="${TARGETFEATURESnogfx} agl-refhw-h3"
            export TARGETMACHINE="h3ulcb"
            ;;
        raspberrypi4)
            export TARGETMACHINE="raspberrypi4-64"
            ;;
    esac

    # Avoid .gitconfig.lock races when multiple jobs start simultaneously
    sleep $((1 + RANDOM % 10))

    if [[ ! -f ~/.gitconfig ]]; then
        git config --global user.email "jenkins-dontreply@build.automotivelinux.org"
        git config --global user.name  "jenkins-dontreply@build.automotivelinux.org"
    fi

    echo "=== init_env complete ==="
    set | grep -E '^(TARGET|GERRIT|MACHINE|NOGFX)' || true
}

# Map CI-system-agnostic CI variables from GH Actions equivalents when Jenkins
# equivalents are absent. Call before init_env.
map_ci_vars() {
    export BUILD_URL="${BUILD_URL:-${GITHUB_SERVER_URL:-}/${GITHUB_REPOSITORY:-}/actions/runs/${GITHUB_RUN_ID:-}}"
    export BUILD_ID="${BUILD_ID:-${GITHUB_RUN_ID:-0}}"
    export BUILD_NUMBER="${BUILD_NUMBER:-${GITHUB_RUN_NUMBER:-0}}"
    export JOB_NAME="${JOB_NAME:-${GITHUB_WORKFLOW:-unknown}}"
    export WORKSPACE="${WORKSPACE:-$(pwd)}"
}
