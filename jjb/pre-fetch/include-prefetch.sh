#!/bin/bash

#set -x
set +e
#
export BOARDS="qemux86-64 qemuarm qemuarm64 raspberrypi4 raspberrypi5 h3ulcb-nogfx"
export FEATURES="agl-demo agl-devel agl-netboot agl-ci"
export FEATURES_nogfx="agl-netboot agl-devel agl-ci"
export TARGETIMAGE="agl-ivi-demo-qt agl-ivi-demo-flutter"
export TARGETIMAGE_nogfx="agl-image-minimal"

mkdir -p mirror
mkdir -p sstate

#echo "AGL DISTRO MIRROR" >> mirror/index.html
#echo "-----------------" >> mirror/index.html
#date >> mirror/index.html

mv repoclone repoclone2 > /dev/null 2>&1 || true
rm -rf repoclone2 || true
mkdir -p repoclone
cd repoclone

repo init --reference=/opt/AGL/preclone -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo.git
repo sync -j8

# Detect and call install-buildtools
if [ -f "external/openembedded-core/scripts/install-buildtools" ]; then
    external/openembedded-core/scripts/install-buildtools
    source external/openembedded-core/buildtools/environment-setup-x86_64-pokysdk-linux
elif [ -f "external/poky/scripts/install-buildtools" ]; then
    external/poky/scripts/install-buildtools
    source external/poky/buildtools/environment-setup-x86_64-pokysdk-linux
fi

for i in $BOARDS ; do
    pushd .
    if test x"m3ulcb-nogfx" = x"$i" ; then
    FEATURES="${FEATURES_nogfx}"
    TARGETIMAGE="${TARGETIMAGE_nogfx}"
    fi
    if test x"h3ulcb-nogfx" = x"$i" ; then
    FEATURES="${FEATURES_nogfx}"
    TARGETIMAGE="${TARGETIMAGE_nogfx}"
    fi
    source meta-agl/scripts/aglsetup.sh -m ${i} -b build-${i} ${FEATURES}
    ln -sf ../../mirror downloads
    ln -sf ../../sstate sstate-cache
    echo 'BB_GENERATE_MIRROR_TARBALLS = "1"' >> conf/local.conf
    #recipe tar-native-1.28-r0: task do_populate_sysroot_setscene
    #bitbake -k tar-native || true
    bitbake --runall=fetch ${TARGETIMAGE} -k || true
    popd
done

pushd ../mirror
rm -f *.done
( find .  -maxdepth 1 -type d | grep -v uninative | xargs rm -rf ) || true
rm -f *bad-checksum* || true
ls -alh
popd

#ls ../mirror || true
