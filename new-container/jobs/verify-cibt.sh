#!/usr/bin/env bash
# jobs/verify-cibt.sh – Gerrit verify CIBT (CI Boot Test) via LAVA
# Replaces: jjb/ci-AGL-verify/ci-platform-jjb.yaml → verify-CIBT-{testmachine} jobs
#
# Required env: MACHINE, GERRIT_CHANGE_NUMBER, GERRIT_PATCHSET_NUMBER,
#               LAB_AGL_USER, LAB_AGL_TOKEN,
#               SSH_GERRIT_KEY_PATH (for gerrit voting)
# Optional env: GERRIT_REVIEW_HOST (set to enable gerrit +1/-1 posting)
#
# Run: docker run --rm --env-file secrets.env \
#        -v /path/to/keys:/run/secrets/:ro \
#        -v $(pwd)/workspace:/workspace \
#        agl-ci /new-container/jobs/verify-cibt.sh
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"

source "${LIB}/00-ssh.sh"
source "${LIB}/00-env.sh"
source "${LIB}/10-repo.sh"
source "${LIB}/20-select.sh"
source "${LIB}/51-lava.sh"
source "${LIB}/52-email-kci.sh"
source "${LIB}/90-gerrit-review.sh"

export WORKSPACE="${WORKSPACE:-$(pwd)}"
cd "${WORKSPACE}"

setup_ssh
map_ci_vars
init_env "$@"

# Repo fetch (CIBT needs releng-scripts; a minimal repo sync is sufficient)
repo_init_sync
cd "${REPODIR}"
repo_select

# Setup releng-scripts
lava_setup_releng

# Determine board mapping for this testmachine
lava_prepare_boardout

# Find an available LAVA lab device
lava_find_lab

# Create and submit the LAVA test job, wait for results
lava_create_job
lava_submit_wait

# Post gerrit vote (no-op unless GERRIT_REVIEW_HOST is configured)
if [[ "${GOODJOB}" -eq 1 ]]; then
    gerrit_vote pass
else
    gerrit_vote fail
fi

# Optionally publish KCI build metadata
kci_publish || true
send_email_report || true
