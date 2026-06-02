#!/bin/bash
# Script: build-ycl.sh
# Description:
#   Replicates the AGL CI platform 'ci-platform-{project}-verify-YCL-qemux86-64'
#   Jenkins job logic into a standalone, reproducible shell environment.
#
# Usage:
#   ./build-ycl.sh <project> <gerrit_change_number> <gerrit_patchset_number>
#
# Arguments:
#   project                 The AGL project name (e.g., meta-agl, meta-agl-demo).
#   gerrit_change_number    The Gerrit Change-Id numeric identifier for the review.
#   gerrit_patchset_number  The specific patchset revision to build.
#
# Detailed Explanation:
#   This script automates the Yocto Check-Layer (YCL) verification process for
#   an AGL project. It bypasses full AGL setup and directly triggers the
#   YCL CI logic defined in common libraries.
#
# Examples:
#   1. Run YCL verification for the base AGL meta-layer:
#      ./build-ycl.sh meta-agl 8313 2
#
#   2. Run YCL verification for a demo project layer:
#      ./build-ycl.sh meta-agl-demo 9001 1
#
#   3. Run YCL check for a development layer:
#      ./build-ycl.sh meta-agl-devel 7888 4
#
# Notes:
#   - Focuses specifically on layer compliance and Yocto compatibility.
#   - Assumes dependencies for YCL-CI are available in the current environment.
#
# Error Handling:
#   - Exits with status 1 if argument count is incorrect.
#   - Fails if the sourced include-scripts are missing or fail internally.

if [ "$#" -ne 3 ]; then
    echo "Error: Invalid number of arguments."
    echo "Usage: $0 <project> <gerrit_change_number> <gerrit_patchset_number>"
    echo ""
    echo "Example:"
    echo "  $0 meta-agl 8313 2"
    exit 1
fi

PROJECT=$1
GERRIT_CHANGE_NUMBER=$2
GERRIT_PATCHSET_NUMBER=$3

export GERRIT_PROJECT="AGL/${PROJECT}"
export GERRIT_CHANGE_NUMBER
export GERRIT_PATCHSET_NUMBER

source ../common/include-agl-header.sh
source ../common/include-agl-repo.sh
source ../common/include-agl-select.sh
# include-agl-source-aglsetup.sh skipped in JJB template
source ../common/include-agl-run-ycl-ci.sh
