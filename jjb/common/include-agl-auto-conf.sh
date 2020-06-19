# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

################################################################################
## auto.conf inclusion of mirrors
################################################################################

export DLHOST="http://download.automotivelinux.org/"
if test x"" = x"${GERRIT_BRANCH}"; then
    export DISTROBRANCH="master"
else
    export DISTROBRANCH="${GERRIT_BRANCH}"
fi
cat << EOF >> conf/auto.conf
PREMIRRORS = "\
git://.*/.* ${DLHOST}/AGL/mirror/   \n \
ftp://.*/.* ${DLHOST}/AGL/mirror/   \n \
http://.*/.* ${DLHOST}/AGL/mirror/  \n \
https://.*/.* ${DLHOST}/AGL/mirror/ \n \
             "

EOF

if test x"YES" != x"${DISABLE_SSTATE_MIRROR}" ; then

cat << EOF >> conf/auto.conf
SSTATE_MIRRORS = " \
  file://.* ${DLHOST}/sstate-mirror/${DISTROBRANCH}/\${DEFAULTTUNE}/PATH \n \
                 "
#
#file://.* file:///opt/AGL/sstate-mirror/\${MACHINE}/PATH    \n 
#

IMAGE_FSTYPES_remove = "ext3"
SSTATE_DIR = "\${TOPDIR}/sstate-cache/\${MACHINE}/"

INHERIT += "packagefeed-stability"
INHERIT += "buildhistory"
EOF

fi

# PRSERV and HASHSERV for CI
# but only starting with dunfell / master -> soon jellyfish
if test x"master" = x"${DISTROBRANCH}" -o x"jellyfish" = x"${DISTROBRANCH}" ; then

export PRHASHSERV="10.30.72.18"
cat << EOF >> conf/auto.conf
# HASHSERVE
BB_HASHSERVE = "${PRHASHSERV}:8686"
BB_SIGNATURE_HANDLER = "OEEquivHash"

PRSERV_HOST = "${PRHASHSERV}:8585"
EOF

fi
