#!/usr/bin/env bash
# jobs/daily-doc-update.sh – daily AGL docs build and GitHub Pages publish
# Replaces: jjb/daily-jjb-doc-update/daily-jjb-doc-update.yaml
#
# Required env: SSH_AGLDOCS_KEY_PATH (GitHub push key)
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"

source "${LIB}/00-ssh.sh"
source "${LIB}/81-docs.sh"

export WORKSPACE="${WORKSPACE:-$(pwd)}"
cd "${WORKSPACE}"

setup_ssh
docs_build
docs_publish
