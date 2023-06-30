# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

################################################################################
## bitbake the image
################################################################################

#if ! test x"${GERRIT_BRANCH}" = x"dab" ; then
#bitbake wic-tools
#fi

cat conf/local.conf


# finally, build the agl-demo-platform (we retry to catch the tar-native bug)
( ( bitbake $TARGETIMAGE ) || ( echo '## Failed once, retry ..  ##' ; sync ; sleep 2 ;  bitbake -v -v $TARGETIMAGE ) ) || ( echo '## Failed again, bail out ...' ; exit 1 ) 

bitbake --dump-signature=none $TARGETIMAGE
cp locked-sigs.inc tmp/deploy/images/
du -hs tmp/deploy/*
