#!/usr/bin/env bash
# lib/20-select.sh – inject gerrit change / select project revision
# Derived from jjb/common/include-agl-select.sh
set -euo pipefail

repo_select() {
    # Must be called from within REPODIR
    local handled=no

    if echo "${TARGETPROJECT}" | grep -q "^AGL/"; then
        local myproject
        myproject=$(echo "${TARGETPROJECT}" | sed -e 's#AGL/##g')

        # meta-renesas and meta-agl-refhw live under bsp/
        if echo "${TARGETPROJECT}" | grep -qE "meta-renesas|meta-agl-refhw"; then
            myproject="bsp/${myproject}"
        fi

        if [[ "${myproject}" == "AGL-repo" ]]; then
            # Manifest change: fast-forward .repo/manifests to the gerrit ref
            pushd .repo/manifests
                local remote
                remote=$(git remote | head -1)
                git fetch "${remote}" "${TARGETREFSPEC}"
                git reset --hard FETCH_HEAD
            popd
            repo sync --force-sync -d
        else
            if [[ -n "${GERRIT_CHANGE_NUMBER:-}" && -n "${GERRIT_PATCHSET_NUMBER:-}" ]]; then
                repo download "${myproject}" "${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER}"
            else
                pushd "${myproject}"
                    local remote
                    remote=$(git remote | head -1)
                    git fetch "${remote}" "${TARGETREFSPEC}"
                    git reset --hard FETCH_HEAD
                popd
            fi
        fi
        handled=yes
    fi

    if [[ "${handled}" != "yes" ]]; then
        echo "ERROR: COULD NOT SELECT PROJECT for TARGETPROJECT=${TARGETPROJECT}"
        set
        exit 1
    fi

    repo manifest -r
    repo manifest -r > ../current_default.xml
}
