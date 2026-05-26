#!/usr/bin/env bash
# lib/31-localconf.sh – composable local.conf / auto.conf fragment writers
# Derived from the include-agl-local-conf-*, include-agl-limit-parallelism,
# include-agl-remove-wic-auto-conf, include-agl-export-eula,
# include-agl-set-*-image include family.
# Each function appends exactly one concern. Call from the job entrypoint.
set -euo pipefail

# Must be called from inside REPODIR/output (i.e. the bitbake build dir)

localconf_limit_parallelism() {
    cat >> conf/auto.conf << 'EOF'

BB_NUMBER_THREADS = "6"
BB_NUMBER_PARSE_THREADS = "6"
PARALLEL_MAKE = "-j6"
EOF
}

localconf_remove_wic() {
    cat >> conf/auto.conf << 'EOF'

IMAGE_FSTYPES:remove = "wic.xz"
IMAGE_FSTYPES:remove = "wic.bmap"
IMAGE_FSTYPES:remove = "wic.vmdk.xz"
EOF
}

localconf_vmdk() {
    if [[ "${MACHINE}" == "qemux86" || "${MACHINE}" == "qemux86-64" ]]; then
        echo 'IMAGE_FSTYPES += "vmdk"' >> conf/local.conf
    fi
}

localconf_archiver() {
    cat >> conf/local.conf << 'EOF'

INHERIT += "archiver"
ARCHIVER_MODE[src] = "original"
COPYLEFT_LICENSE_INCLUDE = "*"
COPYLEFT_LICENSE_EXCLUDE += "CLOSED Proprietary Custom Firmware-* Freescale-* NXP-* TI TI-*"
EOF
}

localconf_ptest() {
    cat >> conf/local.conf << 'EOF'
DISTRO_FEATURES:append = " ptest"
EXTRA_IMAGE_FEATURES:append = " ptest-pkgs"
EOF
}

localconf_distrofeatures_aglci() {
    # Placeholder – the original include was an intentional no-op (commented out).
    # Kept as an explicit function so callers that need it can be found by grep.
    true
}

localconf_export_eula() {
    # Sets the per-machine EULA acceptance variable expected by some BSP layers.
    local eula_var="EULA_$(echo "${MACHINE}" | sed 's/-//g')"
    export "${eula_var}=1"
}

localconf_cat_auto() {
    echo "########## auto.conf ############"
    cat conf/auto.conf
    echo "########## auto.conf ############"
}

# Image-target overrides (matching the include-agl-set-*-image.sh family)

set_compositor_image() {
    export TARGETFEATURES="agl-demo agl-devel agl-netboot"
    export TARGETQA=""
    export TARGETIMAGE="agl-ivi-demo-platform"
}

set_flutter_demo_image() {
    export TARGETIMAGE="agl-ivi-demo-flutter"
}

set_html5_image() {
    export TARGETIMAGE="agl-ivi-demo-html5"
}

set_iceg_lxc_image() {
    export TARGETFEATURES="agl-demo agl-devel agl-netboot"
    export TARGETIMAGE="agl-image-minimal"
}

set_ivieg_flutter_image() {
    export TARGETIMAGE="agl-ivi-demo-flutter"
}
