#!/usr/bin/env bash
# jobs/release-release.sh – promote snapshot sandbox to public release
# Replaces ALL: jjb/release-jjb-{quillback,ricefish,salmon,trout,unagi}-release/
#
# Required env: RELEASE_BRANCH, RELEASE_VERSION, SSH_DOWNLOAD_KEY_PATH
# Optional env: UPLOAD (must be "yes" to actually move files; dry-run otherwise)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"

source "${LIB}/00-ssh.sh"
source "${LIB}/00-env.sh"

export WORKSPACE="${WORKSPACE:-$(pwd)}"
cd "${WORKSPACE}"

: "${RELEASE_BRANCH:?RELEASE_BRANCH must be set}"
: "${RELEASE_VERSION:?RELEASE_VERSION must be set}"

ARTIFACT_HOST="${ARTIFACT_HOST:-jenkins-slave@10.30.72.8}"
ARTIFACT_BASE="${ARTIFACT_BASE:-/srv/download/AGL}"

map_ci_vars
setup_ssh

remotesrc="${ARTIFACT_BASE}/upload/ci/${RELEASE_BRANCH}/${RELEASE_VERSION}/"
remotedst="${ARTIFACT_BASE}/release/${RELEASE_BRANCH}/${RELEASE_VERSION}/"

if [[ "${UPLOAD:-}" == "yes" ]]; then
    ssh "${ARTIFACT_HOST}" mkdir -p "${remotedst}"
    ssh "${ARTIFACT_HOST}" "mv ${remotesrc}* ${remotedst}/ && rm -r ${remotesrc%/}"
    # Update the 'latest' symlink
    ssh "${ARTIFACT_HOST}" \
        "cd ${ARTIFACT_BASE}/release/${RELEASE_BRANCH}/ && \
         rm -f latest && \
         ln -sf ${RELEASE_VERSION} latest && \
         echo ${RELEASE_VERSION} > latest.txt"
    echo "=== release-release: sandbox promoted to ${remotedst} ==="
else
    echo "INFO: UPLOAD is not 'yes', skipping promotion (dry-run)."
fi
