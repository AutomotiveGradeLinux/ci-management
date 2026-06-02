# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

################################################################################
## bitbake the image
################################################################################

# debug
echo 'SSTATE_MIRRORS := ""' >> conf/local.conf

cat conf/local.conf

# finally, build the agl-demo-platform (we retry to catch the tar-native bug)
( ( bitbake $TARGETIMAGE ) || ( echo '## Failed once, retry ..  ##' ; sync ; sleep 2 ;  bitbake -v -v $TARGETIMAGE ) ) || ( echo '## Failed again, bail out ...' ; exit 1 ) 

du -hs tmp/deploy/*
