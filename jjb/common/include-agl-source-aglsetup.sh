# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

################################################################################
## Source the aglsetup script
################################################################################
SETUP_OPTS=""

external/poky/scripts/install-buildtools
source external/poky/buildtools/environment-setup-x86_64-pokysdk-linux


# check aglsetup version
source meta-agl/scripts/aglsetup.sh --version >/dev/null 2>&1 || AGLSETUP_VERSION=1.0.0

# add setup topic (if new enough version)
TOPIC_SUPPORT_VER=1.2.0
if [[ "$(echo -e "$AGLSETUP_VERSION\n$TOPIC_SUPPORT_VER" | sort -V | head -n1)" == $TOPIC_SUPPORT_VER ]]; then
   SETUP_OPTS="--topic change-${GERRIT_CHANGE_NUMBER}-${GERRIT_PATCHSET_NUMBER}"
fi

# source the env
source meta-agl/scripts/aglsetup.sh ${SETUP_OPTS} -m ${MACHINE} -b output ${TARGETFEATURES}

# link the shared downloads and sstate-cache

if [ -d /mnt/tank ]; then
  rm downloads sstate-cache -rf || true
  #mkdir -p /mnt/tank/downloads || true
  #ln -sf /mnt/tank/downloads downloads
  ln -sf /mnt/tank/sstate-mirror ../sstate-mirror
  cat << EOF > conf/auto.conf
  SSTATE_DIR = "\${TOPDIR}/../sstate-mirror/${AGLBRANCH}/\${DEFAULTTUNE}/"
  EOF

else
  ln -sf ../../downloads
  ln -sf ../../sstate-cache
fi

echo "" >> conf/local.conf
echo "### ADDED BY AUTOBUILDER ###" >> conf/local.conf
echo "" >> conf/local.conf

# save some pre-build env needed to uniquely identify the source
MANIFEST_R=repo-manifest-r.txt
repo manifest -r > ${MANIFEST_R}
sha1sum ${MANIFEST_R} | awk '{print $1}' > ${MANIFEST_R}.sha1

cat <<EOF > pre-build-env.txt
TARGETBRANCH=${TARGETBRANCH}
TARGETIMAGE=${TARGETIMAGE}
TARGETFEATURES=${TARGETFEATURES}
TARGETMACHINE=${TARGETMACHINE}
TARGETPROJECT=${TARGETPROJECT}
MACHINE=${MACHINE}
GERRIT_CHANGE_NUMBER=${GERRIT_CHANGE_NUMBER}
GERRIT_PATCHSET_NUMBER=${GERRIT_PATCHSET_NUMBER}
EOF



