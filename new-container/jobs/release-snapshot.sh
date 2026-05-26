#!/usr/bin/env bash
# jobs/release-snapshot.sh – release snapshot build + LAVA boot test
# Replaces ALL: jjb/release-jjb-{quillback,ricefish,salmon,trout,unagi}-snapshot/
#
# Required env: MACHINE, RELEASE_BRANCH (e.g. "unagi"), RELEASE_VERSION,
#               SSH_DOWNLOAD_KEY_PATH, LAB_AGL_USER, LAB_AGL_TOKEN
# Optional env: UPLOAD (set "1" to skip rsync), BUILDONLY, DISABLE_SSTATE_MIRROR
#
# Run: MACHINE=qemux86-64 RELEASE_BRANCH=unagi RELEASE_VERSION=17.0.0 \
#        docker run --rm --env-file secrets.env \
#          -v /path/to/keys:/run/secrets/:ro \
#          -v /mnt/tank:/mnt/tank:rw \
#          -v $(pwd)/workspace:/workspace \
#          agl-ci /new-container/jobs/release-snapshot.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"

source "${LIB}/00-ssh.sh"
source "${LIB}/00-env.sh"
source "${LIB}/10-repo.sh"
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

# Release builds use RELEASE_BRANCH/RELEASE_VERSION for repo manifest selection;
# select.sh is not used (no gerrit change to cherry-pick).
repo_init_sync
cd "${REPODIR}"

run_aglsetup

cd "${REPODIR}/output"
localconf_export_eula
localconf_archiver
localconf_ptest
localconf_distrofeatures_aglci
localconf_vmdk
localconf_limit_parallelism
localconf_cat_auto

# Build image and SDK
bitbake_image "${TARGETIMAGE}"
bitbake_sdk

# Publish deploy tree to download server (skip if UPLOAD=1)
if [[ "${UPLOAD:-}" != "1" ]]; then
    cd "${REPODIR}"
    lava_setup_releng
    lava_prepare_boardout
    publish_release
fi

# LAVA boot test
lava_find_lab
lava_create_job
lava_submit_wait
