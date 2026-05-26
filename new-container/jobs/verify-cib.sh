#!/usr/bin/env bash
# jobs/verify-cib.sh – Gerrit verify CIB (CI Build) per machine
# Replaces: jjb/ci-AGL-verify/ci-platform-jjb.yaml → verify-CIB-{machine} jobs
#
# Required env: MACHINE, GERRIT_PROJECT, GERRIT_BRANCH, GERRIT_REFSPEC,
#               GERRIT_CHANGE_NUMBER, GERRIT_PATCHSET_NUMBER,
#               SSH_GERRIT_KEY_PATH, SSH_DOWNLOAD_KEY_PATH
#
# Optional env: BUILDONLY, TARGETFEATURES, TARGETIMAGE, TARGETSDKIMAGE
#
# Run: docker run --rm --env-file secrets.env \
#        -v /path/to/keys:/run/secrets/:ro \
#        -v /mnt/tank:/mnt/tank:rw \
#        -v $(pwd)/workspace:/workspace \
#        agl-ci /new-container/jobs/verify-cib.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"

source "${LIB}/00-ssh.sh"
source "${LIB}/00-env.sh"
source "${LIB}/10-repo.sh"
source "${LIB}/20-select.sh"
source "${LIB}/30-aglsetup.sh"
source "${LIB}/31-localconf.sh"
source "${LIB}/40-bitbake.sh"
source "${LIB}/51-lava.sh"
source "${LIB}/50-publish.sh"

export WORKSPACE="${WORKSPACE:-$(pwd)}"
cd "${WORKSPACE}"

setup_ssh
map_ci_vars
init_env "$@"

# Repo fetch
repo_init_sync

# Inject gerrit change
cd "${REPODIR}"
repo_select

# Configure build environment
run_aglsetup

# Activate the build dir (aglsetup creates REPODIR/output)
cd "${REPODIR}/output"

localconf_export_eula
localconf_limit_parallelism
localconf_remove_wic
localconf_cat_auto

# Build images
bitbake_image "${TARGETIMAGE}"
bitbake_sdk_x64only

# Prepare LAVA artifact filenames (populates BOARDOUT)
cd "${REPODIR}"
lava_setup_releng
lava_prepare_boardout

# Publish artifacts to download server for CIBT jobs to pick up
cd "${REPODIR}"
publish_changeid
