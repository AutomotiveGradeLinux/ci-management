#!/usr/bin/env bash
# run.sh – launch the built AGL image with runqemu
#
# Run this on your HOST (not inside the build container) so that runqemu can
# access the display. The script locates the build output automatically.
#
# Usage:
#   ./run.sh                      # default: qemux86-64, kvm, graphic off
#   MACHINE=qemux86-64 ./run.sh
#   KVM=0 ./run.sh                # force software emulation (slow)
#   GRAPHICS=1 ./run.sh           # enable graphical output
#   ./run.sh -- nographics serial # extra runqemu arguments
#
# Requirements on the host:
#   qemu-system-x86_64, tunctl/ip tuntap (for networking), /dev/kvm (for speed)
set -euo pipefail

# ── Config (can be overridden by env) ────────────────────────────────────────
MACHINE="${MACHINE:-qemux86-64}"
AGL_IMAGE="${AGL_IMAGE:-agl-demo-platform}"
WORKSPACE="${WORKSPACE:-$(pwd)}"
SRC_DIR="${WORKSPACE}/src"
BUILD_DIR="${SRC_DIR}/output"
KVM="${KVM:-1}"
GRAPHICS="${GRAPHICS:-0}"

# ── Validate ─────────────────────────────────────────────────────────────────
if [[ ! -d "${BUILD_DIR}" ]]; then
    echo "ERROR: build directory not found: ${BUILD_DIR}"
    echo "       Run ./build.sh first (or docker run ... agl-build-container)."
    exit 1
fi

IMAGE_DIR="${BUILD_DIR}/tmp/deploy/images/${MACHINE}"
if [[ ! -d "${IMAGE_DIR}" ]]; then
    echo "ERROR: no images found for ${MACHINE} in ${IMAGE_DIR}"
    exit 1
fi

# runqemu is installed by aglsetup into the build environment
RUNQEMU="${BUILD_DIR}/../meta-agl/../external/poky/scripts/runqemu"
if [[ ! -x "${RUNQEMU}" ]]; then
    # Fall back: find it via the PATH (works if the bitbake env is active)
    RUNQEMU=$(command -v runqemu 2>/dev/null || true)
fi
if [[ -z "${RUNQEMU}" || ! -x "${RUNQEMU}" ]]; then
    echo "ERROR: runqemu not found."
    echo "       Either activate the bitbake environment first:"
    echo "         source ${SRC_DIR}/meta-agl/scripts/aglsetup.sh -m ${MACHINE} -b output ${AGL_FEATURES:-agl-demo agl-devel}"
    echo "       or install qemu-system-x86 on your host."
    exit 1
fi

# ── Build runqemu arguments ───────────────────────────────────────────────────
RUNQEMU_ARGS=("${AGL_IMAGE}")

if [[ "${KVM}" == "1" && -e /dev/kvm ]]; then
    RUNQEMU_ARGS+=("kvm")
else
    echo "INFO: /dev/kvm not available, using software emulation (slow)"
    RUNQEMU_ARGS+=("qemuparams=-machine accel=tcg")
fi

if [[ "${GRAPHICS}" == "0" ]]; then
    RUNQEMU_ARGS+=("nographics" "serialstdio")
else
    RUNQEMU_ARGS+=("sdl")
fi

# Append any extra arguments passed after --
extra=("${@}")

# ── Activate the Yocto environment (needed for runqemu to find the image) ────
# shellcheck disable=SC1090
source "${SRC_DIR}/external/poky/buildtools/environment-setup-x86_64-pokysdk-linux" 2>/dev/null || true

cd "${BUILD_DIR}"
# Source bitbake env so BUILDDIR and other runqemu vars are set correctly
# shellcheck disable=SC1091
source ./oe-init-build-env . > /dev/null 2>&1 || true

echo "=== launching: runqemu ${RUNQEMU_ARGS[*]} ${extra[*]-} ==="
exec "${RUNQEMU}" "${RUNQEMU_ARGS[@]}" "${extra[@]:-}"
