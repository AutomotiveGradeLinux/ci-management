#!/usr/bin/env bash
# jobs/ci-management-verify.sh – verify JJB YAML and optionally run packer validate/build
# Replaces: jjb/ci-management/ci-management.yaml → ci-management-verify-jjb,
#           ci-management-merge-packer-{platforms}-{templates}
#
# Required env: SSH_GERRIT_KEY_PATH
# Optional env: PACKER_ACTION (validate|build), CLOUDENV, PACKER_PLATFORM,
#               PACKER_TEMPLATE
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

source "${LIB}/00-ssh.sh"

export WORKSPACE="${WORKSPACE:-$(pwd)}"
cd "${WORKSPACE}"

setup_ssh

JJB_ACTION="${JJB_ACTION:-test}"     # test | update
PACKER_ACTION="${PACKER_ACTION:-}"   # validate | build (empty = skip packer)

# ------------------------------------------------------------------
# JJB verify / update
# ------------------------------------------------------------------
if command -v jenkins-jobs &>/dev/null; then
    case "${JJB_ACTION}" in
        test)
            echo "=== jenkins-jobs test ==="
            jenkins-jobs test "${REPO_ROOT}/jjb/" -o /tmp/jjb-render
            echo "=== JJB syntax OK ==="
            ;;
        update)
            echo "=== jenkins-jobs update ==="
            jenkins-jobs --conf "${REPO_ROOT}/jenkins.ini" update "${REPO_ROOT}/jjb/"
            ;;
        *)
            echo "Unknown JJB_ACTION=${JJB_ACTION}"; exit 1 ;;
    esac
else
    echo "WARNING: jenkins-jobs not installed, skipping JJB check"
fi

# ------------------------------------------------------------------
# Packer validate / build
# ------------------------------------------------------------------
if [[ -n "${PACKER_ACTION}" ]]; then
    : "${CLOUDENV:?CLOUDENV must point to the cloud credentials file}"
    : "${PACKER_PLATFORM:?PACKER_PLATFORM must be set}"
    : "${PACKER_TEMPLATE:?PACKER_TEMPLATE must be set}"

    packer_tpl="${REPO_ROOT}/packer/templates/${PACKER_PLATFORM}/${PACKER_TEMPLATE}.json"
    [[ -f "${packer_tpl}" ]] || \
        packer_tpl="${REPO_ROOT}/packer/templates/${PACKER_TEMPLATE}.json"

    case "${PACKER_ACTION}" in
        validate)
            packer.io validate \
                -var-file="${CLOUDENV}" "${packer_tpl}" ;;
        build)
            packer.io build \
                -var-file="${CLOUDENV}" "${packer_tpl}" ;;
        *)
            echo "Unknown PACKER_ACTION=${PACKER_ACTION}"; exit 1 ;;
    esac
fi
