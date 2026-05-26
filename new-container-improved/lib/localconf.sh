#!/usr/bin/env bash
# lib/localconf.sh – write developer-friendly local.conf additions
# Call after run_aglsetup (which creates conf/local.conf and conf/auto.conf).
# Must be called from BUILD_DIR.
set -euo pipefail

write_localconf() {
    cat >> conf/auto.conf << EOF

### AGL CI local build additions ###
BB_NUMBER_THREADS = "${BB_NUMBER_THREADS}"
BB_NUMBER_PARSE_THREADS = "${BB_NUMBER_THREADS}"
PARALLEL_MAKE = "${PARALLEL_MAKE}"

# Remove wic variants – not needed for qemu/local testing
IMAGE_FSTYPES:remove = "wic.xz wic.bmap wic.vmdk.xz"
EOF

    # For qemux86-64 add ext4 so runqemu works out of the box
    if [[ "${MACHINE}" == "qemux86-64" ]]; then
        cat >> conf/auto.conf << 'EOF'

# runqemu needs ext4
IMAGE_FSTYPES:append = " ext4"
EOF
    fi

    echo "=== auto.conf ==="
    cat conf/auto.conf
    echo "================="
}
