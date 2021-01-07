# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

################################################################################
## bitbake the image
################################################################################

#if ! test x"${GERRIT_BRANCH}" = x"dab" ; then
#bitbake wic-tools
#fi

echo "#### $MYPROJECT ###"

if test x"meta-agl-devel" = x"$MYPROJECT" ; then 

if test x"qemux86-64" = x"$MACHINE" ; then


TARGETIMAGE="agl-image-boot-basesystem"
TARGETFEATURES="agl-basesystem agl-ci"

echo "#### DO CI FOR $MYPROJECT , $TARGETFEATURES and $TARGETIMAGE"

pushd $REPODIR

SETUP_OPTS="--topic change-${GERRIT_CHANGE_NUMBER}-${GERRIT_PATCHSET_NUMBER}"

# source the env
source meta-agl/scripts/aglsetup.sh ${SETUP_OPTS} -m ${MACHINE} -b output-meta-agl-devel -f ${TARGETFEATURES}

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


# finally, build the agl-demo-platform (we retry to catch the tar-native bug)
( ( bitbake $TARGETIMAGE ) || ( echo '## Failed once, retry ..  ##' ; sync ; sleep 2 ;  bitbake -v -v $TARGETIMAGE ) ) || ( echo '## Failed again, bail out ...' ; exit 1 ) 



du -hs tmp/deploy/*

popd

fi
# / qemux86-64

fi
# / meta-agl-devel