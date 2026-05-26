#!/usr/bin/env bash
# lib/90-gerrit-review.sh – post a Gerrit review vote after LAVA results
# Derived from include-agl-lava-jobs-submit.sh (the gerrit review ssh calls).
# This entire file is gated: if GERRIT_REVIEW_HOST is unset or empty, all
# functions are no-ops so the same entrypoints work on GitHub Actions without
# changes.
set -euo pipefail

gerrit_vote() {
    # $1 = "pass" or "fail"
    local result="${1:-fail}"
    local change="${GERRIT_CHANGE_NUMBER:-}"
    local patchset="${GERRIT_PATCHSET_NUMBER:-}"
    local host="${GERRIT_REVIEW_HOST:-}"
    local port="${GERRIT_REVIEW_PORT:-29418}"
    local user="${GERRIT_REVIEW_USER:-agl-jobbuilder}"
    local key="${GERRIT_REVIEW_KEY:-}"

    # Skip if no Gerrit target configured
    if [[ -z "${host}" || -z "${change}" || -z "${patchset}" ]]; then
        echo "INFO: gerrit_vote skipped (GERRIT_REVIEW_HOST / change info not set)"
        return 0
    fi

    local lines_pct="${LINES_PERCENT:-0}"
    local branches_pct="${BRANCHES_PERCENT:-0}"
    local job_url="${JOB_URL:-${BUILD_URL:-<no url>}}"
    local build_log="${BUILD_URL:-<no url>}consoleFull"

    local msg vote_verified vote_label
    if [[ "${result}" == "pass" ]]; then
        msg="CI-Image-Boot-Test success on ${MACHINE}. Coverage: Lines ${lines_pct}% , Branches ${branches_pct}%
${job_url}"
        vote_verified="+1"
        vote_label="ci-image-boot-test=+1"
    else
        local failed_jobs
        failed_jobs=$(cat job-result.fail 2>/dev/null || true)
        msg="CI-Image-Boot-Test fail on ${MACHINE}. Coverage: Lines ${lines_pct}% , Branches ${branches_pct}%
${job_url}

Build log available at: ${build_log}

Failed jobs:
${failed_jobs}"
        vote_verified="+1"
        vote_label="ci-image-boot-test=-1"
    fi

    # Write message to temp file and escape spaces (matches original behaviour)
    printf '%s' "${msg}" > .gerrit_msg
    sed -i -e "s/ /\\\ /g" .gerrit_msg

    local ssh_opts="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -p ${port}"
    [[ -n "${key}" && -f "${key}" ]] && ssh_opts+=" -i ${key}"

    eval ssh ${ssh_opts} "${user}@${host}" \
        gerrit review "${change},${patchset}" \
        --verified "${vote_verified}" \
        --label "${vote_label}" \
        -n NONE \
        --message '"$(cat .gerrit_msg)"' || true
}
