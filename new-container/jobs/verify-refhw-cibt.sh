#!/usr/bin/env bash
# jobs/verify-refhw-cibt.sh – LAVA boot test for reference hardware
# Replaces: jjb/ci-AGL-refhw-verify/ci-platform-refhw-jjb.yaml → CIBT jobs
#
# Identical to verify-cibt.sh; MACHINE drives the board mapping in 51-lava.sh.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/verify-cibt.sh" "$@"
