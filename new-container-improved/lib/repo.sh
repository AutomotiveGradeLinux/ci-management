#!/usr/bin/env bash
# lib/repo.sh – repo init and sync for AGL source tree
set -euo pipefail

repo_sync() {
    mkdir -p "${SRC_DIR}"

    if [[ "${SKIP_REPO_SYNC}" == "1" && -d "${SRC_DIR}/.repo" ]]; then
        echo "=== SKIP_REPO_SYNC=1: reusing existing source tree ==="
        cd "${SRC_DIR}"
        return
    fi

    cd "${SRC_DIR}"

    # Use local reference mirror if available (e.g. on CI nodes with /opt/AGL/preclone)
    local ref_opt=""
    [[ -d /opt/AGL/preclone ]] && ref_opt="--reference=/opt/AGL/preclone"

    if [[ ! -d .repo ]]; then
        echo "=== repo init (branch: ${AGL_BRANCH}) ==="
        repo init ${ref_opt} \
            -u "${AGL_REPO_URL}" \
            -b "${AGL_BRANCH}"
    else
        echo "=== repo already initialised, syncing ==="
    fi

    echo "=== repo sync ==="
    repo sync --force-broken --force-sync --detach --no-clone-bundle -j"${BB_NUMBER_THREADS}"
}

# Inject a Gerrit change on top of the synced tree.
# Only runs when GERRIT_CHANGE_NUMBER and GERRIT_PATCHSET_NUMBER are both set.
repo_apply_patch() {
    [[ -z "${GERRIT_CHANGE_NUMBER}" || -z "${GERRIT_PATCHSET_NUMBER}" ]] && return 0

    cd "${SRC_DIR}"

    local project="${GERRIT_PROJECT:-}"
    if [[ -z "${project}" ]]; then
        echo "ERROR: GERRIT_PROJECT must be set when applying a patch"
        exit 1
    fi

    # Strip the AGL/ prefix to get the filesystem path inside the repo
    local repo_path
    repo_path=$(echo "${project}" | sed -e 's#AGL/##g')
    # meta-renesas and meta-agl-refhw live under bsp/
    echo "${project}" | grep -qE "meta-renesas|meta-agl-refhw" && \
        repo_path="bsp/${repo_path}"

    echo "=== applying Gerrit patch ${project} ${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER} ==="
    repo download "${repo_path}" "${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER}"
}
