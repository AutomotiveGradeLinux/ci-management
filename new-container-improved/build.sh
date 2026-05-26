#!/usr/bin/env bash
# build.sh – AGL local CI build
#
# Usage inside Docker:
#   docker run --rm \
#     -v $(pwd)/workspace:/workspace \
#     -v $(pwd)/sstate:/sstate-cache \
#     -v $(pwd)/downloads:/downloads \
#     --env-file config.env \
#     agl-build-container
#
# Or directly on the host (if Yocto host deps are installed):
#   source config.env && bash build.sh
#
# After a successful build, run the image with:
#   ./run.sh   (outside the container)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="${SCRIPT_DIR}/lib"

# Auto-source config.env from the script directory when present.
# Variables already in the environment take precedence (set -a exports them all).
if [[ -f "${SCRIPT_DIR}/config.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "${SCRIPT_DIR}/config.env"
    set +a
fi

source "${LIB}/env.sh"
source "${LIB}/repo.sh"
source "${LIB}/aglsetup.sh"
source "${LIB}/localconf.sh"
source "${LIB}/bitbake.sh"

# ── 1. Initialise variables ───────────────────────────────────────────────────
init_env

# ── 2. Fetch sources ──────────────────────────────────────────────────────────
repo_sync

# ── 3. Apply Gerrit patch (no-op when GERRIT_CHANGE_NUMBER is unset) ─────────
repo_apply_patch

# ── 4. Configure build environment ───────────────────────────────────────────
run_aglsetup

# ── 5. Tune local.conf ────────────────────────────────────────────────────────
cd "${BUILD_DIR}"
write_localconf

# ── 6. Build ──────────────────────────────────────────────────────────────────
bitbake_image "${AGL_IMAGE}"

# ── 7. Build SDK (optional) ───────────────────────────────────────────────────
if [[ "${BUILD_SDK}" == "1" ]]; then
    bitbake_sdk "${AGL_IMAGE}"
fi

# ── 8. Print summary ─────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Build complete!                                         ║"
echo "╠══════════════════════════════════════════════════════════╣"
printf "║  Machine : %-45s ║\n" "${MACHINE}"
printf "║  Image   : %-45s ║\n" "${AGL_IMAGE}"
printf "║  Dir     : %-45s ║\n" "${BUILD_DIR}/tmp/deploy/images/${MACHINE}/"
echo "╠══════════════════════════════════════════════════════════╣"
if [[ "${MACHINE}" == "qemux86-64" || "${MACHINE}" =~ ^qemu ]]; then
echo "║  Run with:  ./run.sh                                     ║"
fi
echo "╚══════════════════════════════════════════════════════════╝"
