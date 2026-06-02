#!/bin/bash
# Script: build-machine.sh
# Description:
#   Replicates the AGL CI platform 'ci-platform-{project}-verify-CIB-{machine}'
#   Jenkins job logic into a standalone, reproducible shell environment.
#
# Usage:
#   ./build-machine.sh <project> <machine> <gerrit_change_number> <gerrit_patchset_number>
#
# Arguments:
#   project                 The AGL project name (e.g., meta-agl, meta-agl-demo, AGL-repo).
#   machine                 The target hardware/emulator (e.g., qemux86-64, raspberrypi4, h3ulcb-nogfx).
#   gerrit_change_number    The Gerrit Change-Id numeric identifier for the review.
#   gerrit_patchset_number  The specific patchset revision to build.
#
# Detailed Explanation:
#   This script automates the full AGL build cycle for a specified target machine.
#   It invokes the common AGL CI library, sets up the workspace, configures the
#   BitBake environment, and executes the build process.
#
# Examples:
#   1. Standard build for meta-agl on a generic 64-bit x86 emulator:
#      ./build-machine.sh meta-agl qemux86-64 8313 2
#
#   2. Build for a Raspberry Pi 4 target:
#      ./build-machine.sh meta-agl raspberrypi4 8500 1
#
#   3. Build for automotive Renesas hardware:
#      ./build-machine.sh meta-agl-demo h3ulcb-nogfx 9122 3
#
#   4. Build an AGL-repo component for RISC-V:
#      ./build-machine.sh AGL-repo qemuriscv 7700 5
#
# Notes:
#   - This script assumes a valid AGL CI environment is set up in the parent directory.
#   - Ensure you have the necessary SSH permissions for the AGL infrastructure
#     if you are running in a CI runner context.
#
# Error Handling:
#   - Exits with status 1 if argument count is incorrect.
#   - Fails if the sourced include-scripts are missing or fail internally.

if [ "$#" -ne 4 ]; then
    echo "Error: Invalid number of arguments."
    echo "Usage: $0 <project> <machine> <gerrit_change_number> <gerrit_patchset_number>"
    echo ""
    echo "Example:"
    echo "  $0 meta-agl qemux86-64 8313 2"
    exit 1
fi

PROJECT=$1
MACHINE=$2
GERRIT_CHANGE_NUMBER=$3
GERRIT_PATCHSET_NUMBER=$4

export MACHINE
export GERRIT_PROJECT="AGL/${PROJECT}"
export GERRIT_CHANGE_NUMBER
export GERRIT_PATCHSET_NUMBER

source ../common/include-agl-header.sh
source ../common/include-agl-repo.sh
source ../common/include-agl-select.sh
source ../common/include-agl-source-aglsetup.sh
source ../common/include-agl-auto-conf.sh
source ../common/include-agl-limit-parallelism.sh
source ../common/include-agl-remove-wic-auto-conf.sh
source ../common/include-agl-cat-auto-conf.sh
source ../common/include-agl-bitbake-image.sh
source ../common/include-agl-bitbake-sdk-x64only.sh
source ../common/include-agl-run-test-prepare.sh
source ../common/include-agl-run-test-rsync-changeid.sh
source ../common/include-agl-setup-and-bitbake-ivi-image.sh
