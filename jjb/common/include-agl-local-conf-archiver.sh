# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

################################################################################
## Add archiver
################################################################################

# archive sources within  tmp/deploy/
cat >> conf/local.conf << EOF

# Archiver setup
INHERIT += "archiver"
ARCHIVER_MODE[src] = "original"
COPYLEFT_LICENSE_INCLUDE = "*"
COPYLEFT_LICENSE_EXCLUDE += "CLOSED Proprietary Custom Firmware-* Freescale-* NXP-* TI TI-*"

EOF

# Later (YP master) : generate full mirror using
#INHERIT += "archiver"
#BB_GENERATE_MIRROR_TARBALLS = "1"
#BB_GENERATE_SHALLOW_TARBALLS = "1"
#BB_GIT_SHALLOW = "1"
#ARCHIVER_MODE[src] = "mirror"
#ARCHIVER_MODE[mirror] = "combined"
#ARCHIVER_MIRROR_EXCLUDE = "file://"
#COPYLEFT_LICENSE_INCLUDE = "*"

