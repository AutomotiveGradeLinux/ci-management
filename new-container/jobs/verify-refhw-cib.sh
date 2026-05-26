#!/usr/bin/env bash
# jobs/verify-refhw-cib.sh – Gerrit verify CIB for reference hardware (Renesas RCar)
# Replaces: jjb/ci-AGL-refhw-verify/ci-platform-refhw-jjb.yaml → CIB jobs
#
# Identical pipeline to verify-cib.sh; the refhw differentiation is fully
# captured by MACHINE=h3ulcb-nogfx (or r8a7795-agl-refhw) and
# GERRIT_PROJECT=AGL/meta-renesas-rcar-gen3.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Delegate entirely – refhw CIB is structurally the same as platform CIB.
exec "${SCRIPT_DIR}/verify-cib.sh" "$@"
