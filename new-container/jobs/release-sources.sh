#!/usr/bin/env bash
# jobs/release-sources.sh – create and publish AGL sources tarball
# Replaces ALL: jjb/release-jjb-{quillback,ricefish,salmon,trout,unagi}-sources/
#
# Required env: RELEASE_BRANCH, RELEASE_VERSION, GERRIT_BRANCH,
#               SSH_DOWNLOAD_KEY_PATH
# Optional env: UPLOAD (must be "yes" to rsync; dry-run otherwise),
#               ARTIFACT_HOST, ARTIFACT_BASE
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/../lib"

source "${LIB}/00-ssh.sh"
source "${LIB}/00-env.sh"

export WORKSPACE="${WORKSPACE:-$(pwd)}"
cd "${WORKSPACE}"

: "${RELEASE_BRANCH:?RELEASE_BRANCH must be set}"
: "${RELEASE_VERSION:?RELEASE_VERSION must be set}"

ARTIFACT_HOST="${ARTIFACT_HOST:-jenkins-slave@10.30.72.8}"
ARTIFACT_BASE="${ARTIFACT_BASE:-/srv/download/AGL}"

map_ci_vars
setup_ssh

# Ensure repo tool is available
if ! command -v repo &>/dev/null; then
    mkdir -p ~/bin
    curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo-1 -o ~/bin/repo
    chmod a+x ~/bin/repo
    export PATH="$HOME/bin:$PATH"
fi

local_ref=""
[[ -d /opt/AGL/preclone ]] && local_ref="--reference=/opt/AGL/preclone"

# Create a clean source tree from the release manifest
local_dir="agl-${RELEASE_BRANCH}-${RELEASE_VERSION}"
rm -rf "${local_dir}" || true
mkdir "${local_dir}"
pushd "${local_dir}"
    repo init --repo-branch=repo-1 ${local_ref} -q \
        -b "${GERRIT_BRANCH:-master}" \
        -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo \
        -m "${RELEASE_BRANCH}_${RELEASE_VERSION}.xml"
    repo sync --force-sync
    repo manifest -r > "../${RELEASE_BRANCH}_${RELEASE_VERSION}.tar.xml"

    # Strip .git dirs so the tarball is a clean source snapshot
    rm -rf .repo
    find . -name "*.git" | xargs rm -rf

    ln -sf meta-agl/README-AGL.md
    cat > aglsetup.sh << 'EOF'
#!/bin/bash
source ./meta-agl/scripts/aglsetup.sh "$@"
EOF
    chmod a+x aglsetup.sh
popd

# Package
tar -cjvf "${local_dir}.tar.bz2" "${local_dir}"
md5sum    "${local_dir}.tar.bz2" > "${local_dir}.tar.bz2.md5sum"
sha256sum "${local_dir}.tar.bz2" > "${local_dir}.tar.bz2.sha256sum"

rm -rf UPLOAD || true
mkdir -p UPLOAD/
cp -a "agl-${RELEASE_BRANCH}-${RELEASE_VERSION}".* UPLOAD/
ls -alh UPLOAD/

if [[ "${UPLOAD:-}" == "yes" ]]; then
    local rsyncdst="${ARTIFACT_BASE}/release/${RELEASE_BRANCH}/"
    ssh "${ARTIFACT_HOST}" mkdir -p "${rsyncdst}"
    rsync -avr -e ssh UPLOAD/* "${ARTIFACT_HOST}:${rsyncdst}"
    ssh "${ARTIFACT_HOST}" \
        "rm -rf ${rsyncdst}/latest && ln -sf ${RELEASE_VERSION} ${rsyncdst}/latest"
    echo "=== release-sources: uploaded to ${rsyncdst} ==="
else
    echo "INFO: UPLOAD is not 'yes', skipping rsync (dry-run)."
fi
