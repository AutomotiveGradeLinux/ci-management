# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

################################################################################
## Source the aglsetup script
################################################################################

# source the env
source meta-agl/scripts/aglsetup.sh -m ${MACHINE} -b output ${TARGETFEATURES}

# link the shared downloads and sstate-cache
ln -sf ../../downloads
ln -sf ../../sstate-cache

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
