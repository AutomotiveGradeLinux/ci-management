#!/usr/bin/env bash
# shell.sh – drop into an interactive shell inside the agl-build-container build container
#
# Usage:
#   ./shell.sh                    # plain bash prompt, caches mounted
#   ./shell.sh --bootstrap        # also run aglsetup so bitbake is ready
#   MACHINE=qemuarm64 ./shell.sh  # override machine
#
# Inside the container you can run any bitbake command directly:
#   bitbake agl-ivi-demo-flutter
#   bitbake -c devshell <recipe>
#   bitbake -e <recipe> | grep ^SRC_URI
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Auto-source config.env so env vars reach docker --env-file
if [[ -f "${SCRIPT_DIR}/config.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/config.env"
    set +a
fi

WORKSPACE="${WORKSPACE:-${SCRIPT_DIR}}"
BOOTSTRAP=0
if [[ "${1:-}" == "--bootstrap" ]]; then
    BOOTSTRAP=1
    shift
fi

if [[ "${BOOTSTRAP}" == "1" ]]; then
    ENTRYPOINT_ARGS=(bash -c '
        source /agl-ci/lib/env.sh && init_env
        source /agl-ci/lib/repo.sh
        source /agl-ci/lib/aglsetup.sh
        repo_sync
        run_aglsetup
        cd "${BUILD_DIR}"
        echo ""
        echo "Build environment ready. BUILD_DIR=${BUILD_DIR}"
        echo "Run: bitbake ${AGL_IMAGE}"
        echo ""
        exec bash --login
    ')
else
    ENTRYPOINT_ARGS=(bash --login)
fi

echo "=== Launching interactive shell (MACHINE=${MACHINE:-qemux86-64}) ==="
[[ "${BOOTSTRAP}" == "1" ]] && echo "    --bootstrap: will run repo sync + aglsetup before dropping to shell"

exec docker run --rm -it \
    -v "${WORKSPACE}:/workspace" \
    -v "${SCRIPT_DIR}/sstate:/sstate-cache" \
    -v "${SCRIPT_DIR}/downloads:/downloads" \
    --env-file "${SCRIPT_DIR}/config.env" \
    --entrypoint "" \
    agl-build-container \
    "${ENTRYPOINT_ARGS[@]}"
