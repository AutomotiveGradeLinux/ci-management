#!/bin/bash
# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2
#
# debugging purposes
set -e

################################################################################
# build the app
################################################################################

# fallback
if test -z "${GERRIT_PROJECT}"; then
    export GERRIT_PROJECT="apps/settings"
fi
if test -z "${GERRIT_BRANCH}"; then
    export GERRIT_BRANCH="master"
fi
if test -z "${GERRIT_REFSPEC}"; then
    export GERRIT_REFSPEC="refs/tags/icefish_8.99.4"
fi
if test -z "${GERRIT_HOST}"; then
    export GERRIT_HOST="gerrit.automotivelinux.org"
fi

# apply GERRIT_*
if test -n "${GERRIT_PROJECT}"; then
    export TARGETPROJECT="${GERRIT_PROJECT}"
fi
if test -n "${GERRIT_BRANCH}"; then
    export TARGETBRANCH="${GERRIT_BRANCH}"
fi
if test -n "${GERRIT_REFSPEC}"; then
    export TARGETREFSPEC="${GERRIT_REFSPEC}"
fi


ls
pwd


HANDLED="no"

# Projects in apps/*
###################
if [[ ! x"yes" = x"$HANDLED" ]] && $(echo "$TARGETPROJECT" | grep -q "apps/"); then

    MYPROJECT=`echo $TARGETPROJECT | sed -e "s#apps/##g"`

    # clone git
    rm -rf ${MYPROJECT}
    git clone --recurse-submodules --recursive https://${GERRIT_HOST}/gerrit/${GERRIT_PROJECT}.git
    pushd ${MYPROJECT}
        git log -1 --pretty=oneline
        if test x"" != x"${TARGETREFSPEC}" ; then
          git fetch origin ${TARGETREFSPEC}
          git reset --hard FETCH_HEAD
        else
          # try 
          # GERRIT_CHANGE_NUMBER="9551"
          # GERRIT_PATCHSET_NUMBER="2"
          if ( test x"" != x"${GERRIT_CHANGE_NUMBER}" -a x"" != x"${GERRIT_PATCHSET_NUMBER}" ) ; then
            pip install --user git-review
            git review -d ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER}
          fi
          sleep 2
          # if not reset, we leave it to master
        fi

        # update git submodules
        if test -f .gitmodules ; then
           git submodule init && git submodule update
        fi

        git log -1 --pretty=oneline

        # Fixme: use aglbuild script
        #set -x
        MYPROJSRC=`pwd`
    popd

    mkdir AGL
    pushd AGL
    repo init --reference=/opt/AGL/preclone -q -b $TARGETBRANCH -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo
    repo sync --force-sync -d -j12
    
    source meta-agl/scripts/aglsetup.sh -m qemux86-64 agl-demo agl-devel agl-voiceagent-alexa agl-cluster-demo 

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

EOF

fi


    # do externalsrc for the app build
cat << EOF >> conf/auto.conf
#
INHERIT += "externalsrc"
EXTERNALSRC_pn-${MYPROJECT} = "${MYPROJSRC}"

EOF

    cat conf/auto.conf

    bitbake $MYPROJECT

    HANDLED="yes"
fi
