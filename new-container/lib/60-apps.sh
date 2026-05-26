#!/usr/bin/env bash
# lib/60-apps.sh – AGL application build helpers
# Derived from include-apps-build-app.sh, include-apps-fetch-install-sdk.sh,
# include-apps-rsync-download-*.sh, include-apps-prepare-upload-folder*.sh.
set -euo pipefail

apps_clone_project() {
    local gerrit_host="${GERRIT_HOST:-gerrit.automotivelinux.org}"
    local project="${GERRIT_PROJECT:-apps/controls}"
    local myproject
    myproject=$(echo "${project}" | sed 's#apps/##g')

    rm -rf "${myproject}"
    git clone --recurse-submodules \
        "https://${gerrit_host}/gerrit/${project}.git"

    pushd "${myproject}"
        git log -1 --pretty=oneline
        if [[ -n "${GERRIT_REFSPEC:-}" ]]; then
            git fetch origin "${GERRIT_REFSPEC}"
            git reset --hard FETCH_HEAD
        elif [[ -n "${GERRIT_CHANGE_NUMBER:-}" && -n "${GERRIT_PATCHSET_NUMBER:-}" ]]; then
            git fetch origin \
                "refs/changes/${GERRIT_CHANGE_NUMBER: -2}/${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER}"
            git reset --hard FETCH_HEAD
        fi
    popd
    export MYPROJECT="${myproject}"
}

apps_fetch_sdk() {
    local aglbranch="${AGLBRANCH:-master}"
    local targetsdkmachine="${TARGETSDKMACHINE:-qemux86-64}"

    case "${aglbranch}" in
        albacore|blowfish|chinook|dab)
            echo "Unsupported branch ${aglbranch}"; return 0 ;;
    esac

    local sdk_base_url="http://mirror.automotivelinux.org/AGL/release/${aglbranch}/latest/${targetsdkmachine}/deploy/sdk/"
    [[ "${aglbranch}" == "master" || "${aglbranch}" == "halibut" ]] && \
        sdk_base_url="http://mirror.automotivelinux.org/AGL/snapshots/${aglbranch}/latest/${targetsdkmachine}/deploy/sdk/"

    local sdk_name
    sdk_name=$(curl -s "${sdk_base_url}" \
        | grep -E "crosssdk.*\.sh<" \
        | sed -e 's/.*<a href="//g' -e 's/">.*//' \
        | head -1)

    [[ -n "${sdk_name}" ]] || { echo "ERROR: could not find SDK at ${sdk_base_url}"; exit 1; }

    if [[ ! -f "${sdk_name}" ]]; then
        wget -nd -c "${sdk_base_url}/${sdk_name}"
    fi
    chmod a+x "${sdk_name}"
    ./"${sdk_name}" -y -d "${SDKHOSTDIR:-${HOME}/agl-sdk}"
    export SDK_ENV
    SDK_ENV=$(ls "${SDKHOSTDIR:-${HOME}/agl-sdk}/environment-setup"* | grep agl | head -1)
}

apps_build() {
    [[ -n "${SDK_ENV:-}" ]] || { echo "ERROR: SDK_ENV not set"; exit 1; }
    # shellcheck disable=SC1090
    source "${SDK_ENV}"
    pushd "${MYPROJECT}"
        if [[ -f CMakeLists.txt ]]; then
            mkdir -p build && cd build
            cmake .. && make
        elif [[ -f configure.ac || -f configure ]]; then
            [[ -f configure ]] || autoreconf -i
            ./configure && make
        else
            make
        fi
    popd
}

apps_rsync_download_changeid() {
    local download_url="http://download.automotivelinux.org/AGL/upload/ci/${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER}"
    local machine="${TARGETSDKMACHINE:-qemux86-64}"
    mkdir -p download
    # Download and install the SDK published by the CIB job
    wget -nd -r -np -A "*.sh" "${download_url}/${machine}/deploy/sdk/" -P download/ || true
    for sdk in download/*.sh; do
        [[ -f "${sdk}" ]] || continue
        chmod a+x "${sdk}"
        "${sdk}" -y -d "${SDKHOSTDIR:-${HOME}/agl-sdk}"
    done
}

apps_prepare_upload_folder() {
    local dest="${WORKSPACE}/UPLOAD/${GERRIT_PROJECT}/${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER}"
    mkdir -p "${dest}"
    if [[ -d "${MYPROJECT}/build" ]]; then
        find "${MYPROJECT}/build" -name "*.wgt" -exec cp {} "${dest}/" \;
    fi
    echo "Upload folder contents:"
    ls -alh "${dest}" || true
}
