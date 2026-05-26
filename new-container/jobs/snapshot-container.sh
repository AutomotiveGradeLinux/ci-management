#!/usr/bin/env bash
# jobs/snapshot-container.sh – build and publish the AGL Docker worker container
# Replaces: jjb/snapshot-jjb-container/snapshot-jjb-container.yaml
#
# Required env: BUILD_ID (or BUILD_NUMBER), ARTIFACT_HOST, SSH_DOWNLOAD_KEY_PATH
# Run: docker run --rm --env-file secrets.env \
#        -v /path/to/ssh_download:/run/secrets/ssh_download:ro \
#        -v $(pwd)/workspace:/workspace \
#        agl-ci /new-container/jobs/snapshot-container.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"

# shellcheck source=../lib/00-ssh.sh
source "${LIB}/00-ssh.sh"
# shellcheck source=../lib/70-container.sh
source "${LIB}/70-container.sh"

export WORKSPACE="${WORKSPACE:-$(pwd)}"
cd "${WORKSPACE}"

setup_ssh
container_build
container_publish
