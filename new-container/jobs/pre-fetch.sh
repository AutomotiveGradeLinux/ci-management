#!/usr/bin/env bash
# jobs/pre-fetch.sh – weekly download-mirror pre-fetch
# Replaces: jjb/pre-fetch/pre-fetch.yaml
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"

source "${LIB}/00-ssh.sh"
source "${LIB}/80-prefetch.sh"

export WORKSPACE="${WORKSPACE:-$(pwd)}"
cd "${WORKSPACE}"

setup_ssh
prefetch_run
prefetch_publish
