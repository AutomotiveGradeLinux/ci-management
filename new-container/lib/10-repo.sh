#!/usr/bin/env bash
# lib/10-repo.sh – repo init / sync
# Derived from jjb/common/include-agl-repo.sh
set -euo pipefail

repo_init_sync() {
    mkdir -p ~/bin

    # Use system repo if present; otherwise fall back to downloaded copy
    if [[ ! -f /usr/local/bin/repo && ! -f /usr/bin/repo ]]; then
        if [[ ! -f ~/bin/repo ]]; then
            curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo -o ~/bin/repo
            chmod a+x ~/bin/repo
        fi
        export PATH="$HOME/bin:$PATH"
    fi

    mkdir -p downloads sstate-cache

    # Use a process-unique subdirectory so parallel jobs on the same host don't collide
    export XTMP="$$"
    mkdir -p "repoclone${XTMP}"
    cd "repoclone${XTMP}"
    export REPODIR="$(pwd)"

    # Write REPODIR to state file so subsequent steps can source it
    echo "export REPODIR=\"${REPODIR}\"" >> "${WORKSPACE:-.}/.state.env"

    local repo_url="https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo"
    local ref_opt="--reference=/opt/AGL/preclone"
    # Skip reference if the preclone mirror is absent (local dev / container without NFS)
    [[ -d /opt/AGL/preclone ]] || ref_opt=""

    if [[ -z "${RELEASE_VERSION:-}" && -z "${RELEASE_BRANCH:-}" ]]; then
        repo init ${ref_opt} -b "${TARGETBRANCH}" -u "${repo_url}"
    elif [[ "${TARGETPROJECT:-}" == "AGL/meta-renesas-rcar-gen3" ]]; then
        repo init ${ref_opt} -q -b master -u "${repo_url}"
    else
        repo init ${ref_opt} -q -b "${TARGETBRANCH}" \
            -m "${RELEASE_BRANCH}_${RELEASE_VERSION}.xml" -u "${repo_url}"
    fi

    repo sync --force-broken --force-sync --detach --no-clone-bundle
}
