#!/usr/bin/env bash
# jobs/verify-ycl.sh – yocto-check-layer CI for AGL layers (qemux86-64 only)
# Replaces: jjb/ci-AGL-verify/ci-platform-jjb.yaml → verify-YCL-qemux86-64
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"

source "${LIB}/00-ssh.sh"
source "${LIB}/00-env.sh"
source "${LIB}/10-repo.sh"
source "${LIB}/20-select.sh"
source "${LIB}/40-bitbake.sh"

export WORKSPACE="${WORKSPACE:-$(pwd)}"
export MACHINE="${MACHINE:-qemux86-64}"
cd "${WORKSPACE}"

setup_ssh
map_ci_vars
init_env "$@"

repo_init_sync
cd "${REPODIR}"
repo_select

bitbake_ycl
