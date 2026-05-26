#!/usr/bin/env bash
# lib/aglsetup.sh – install buildtools, run aglsetup.sh, wire up caches
set -euo pipefail

run_aglsetup() {
    cd "${SRC_DIR}"

    # Install poky build tools (cross-compiler, Python, cmake, …)
    echo "=== install-buildtools ==="
    external/poky/scripts/install-buildtools --without-extended-buildtools 2>&1 | tail -5 || \
        external/poky/scripts/install-buildtools 2>&1 | tail -5

    # aglsetup.sh and the poky environment scripts reference zsh-specific
    # variables (ZSH_EVAL_CONTEXT) without guarding them. Suspend -u so that
    # unset variables in those external scripts don't abort our build.
    set +u
    # shellcheck disable=SC1091
    source external/poky/buildtools/environment-setup-x86_64-pokysdk-linux

    echo "=== aglsetup.sh -m ${MACHINE} -b output ${AGL_FEATURES} ==="
    # shellcheck disable=SC1091
    source meta-agl/scripts/aglsetup.sh \
        -m "${MACHINE}" \
        -b output \
        ${AGL_FEATURES}
    set -u

    # Wire up persistent downloads and sstate directories.
    # These are bind-mounted from the host so they survive container restarts.
    cd "${BUILD_DIR}"

    # downloads
    if [[ -d "${DOWNLOADS_DIR}" ]]; then
        rm -rf downloads
        ln -sf "${DOWNLOADS_DIR}" downloads
    else
        mkdir -p downloads
    fi

    # sstate-cache: use a machine+branch-specific subdir to avoid tune conflicts
    local sstate_subdir="${SSTATE_DIR}/${AGL_BRANCH}/${MACHINE}"
    mkdir -p "${sstate_subdir}"
    rm -rf sstate-cache
    ln -sf "${sstate_subdir}" sstate-cache

    echo "=== aglsetup done. AGL_BRANCH=${AGL_BRANCH:-<unset>} ==="
}
