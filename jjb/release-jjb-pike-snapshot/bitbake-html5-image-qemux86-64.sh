# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

################################################################################
## bitbake the sdk
################################################################################
#if ! test x"${GERRIT_BRANCH}" = x"dab" ; then
#bitbake wic-tools
#fi

if test x"qemux86-64" = x"${TARGETMACHINE}" ; then

# finally, build the agl-demo-platform (we retry to catch the tar-native bug)
#( ( bitbake -c $TARGETSDK $TARGETIMAGE ) || ( echo '## Failed once, retry ..  ##' ; sync ; sleep 2 ; bitbake -c $TARGETSDK $TARGETIMAGE ) ) || ( echo '## Failed again, bail out ... ##' ; exit 1 ) 
echo 'AGL_DEFAULT_IMAGE_FSTYPES_forcevariable = "wic.vmdk.xz wic.xz ext4.xz"' >> conf/local.conf
echo 'AGL_EXTRA_IMAGE_FSTYPES_forcevariable = ""' >> conf/local.conf
( ( bitbake agl-demo-platform-html5 ) || ( echo '## Failed once, retry ..  ##' ; sync ; sleep 2 ; bitbake agl-demo-platform-html5 ) ) || ( echo '## Failed again, bail out ... ##' ; exit 1 ) 

du -hs tmp/deploy/*

fi