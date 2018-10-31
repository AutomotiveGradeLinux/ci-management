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
    export GERRIT_PROJECT="apps/controls"
fi
if test -z "${GERRIT_BRANCH}"; then
    export GERRIT_BRANCH="master"
fi
if test -z "${GERRIT_REFSPEC}"; then
    export GERRIT_REFSPEC="refs/tags/dab_3.99.1"
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
        set -x

        export DONE=0
        export isAUTOBUILD=0
	if [[ -f autobuild/agl/autobuild ]]
	then
            mkdir -p $(pwd)/package/
	    chmod a+x autobuild/agl/autobuild
	    autobuild/agl/autobuild package DEST=$(pwd)/package
            export isAUTOBUILD=1
            export DONE=1
	else
            echo "Your binding doesn't use an autobuild script. Please add it in your project."
	    echo "It has to be stored in your root project directory in autobuild/agl/autobuild file"
	    echo "and be able to generate an AGL package in the build root directory using the call"
	    echo "autobuild/agl/autobuild package DEST=build"
        fi

        ######################################################################
        # /!\/!\/!\   DEPRECATED FALLBACK WAY TO BUILD AGL APPS /!\/!\/!\    #
        ######################################################################

        export isCMAKE=0
        export isMAKE=0
        export isQMAKE=0

        if test x"0" = x"$DONE" -a -f conf.d/autobuild/agl/autobuild ; then
            mkdir -p $(pwd)/package/
            conf.d/autobuild/agl/autobuild package DEST=$(pwd)/package/
            export isAUTOBUILD=1
            export DONE=1
        fi
        if test x"0" = x"$DONE" -a -f CMakeLists.txt; then
            rm -rf build || true
            mkdir build
            pushd build
            cmake ../
            make
            if test x"0" = x"$DONE" -a -f ../conf.d/autobuild/agl/autobuild ; then
                ../conf.d/autobuild/agl/autobuild package DEST=$(pwd)/package
                export isAUTOBUILD=1
	    else
                make package || true
	    fi
            popd
            export isCMAKE=1
            export DONE=1
        fi
        if test x"0" = x"$DONE" -a -f Makefile ; then
            make
            make package
            export isMAKE=1
            export DONE=1
        fi
        if test x"0" = x"$DONE" -a -f ${MYPROJECT}.pro; then
            qmake
            make
            make package
            export isQMAKE=1
            export DONE=1
        fi
        ######################################################################
        # /!\/!\/!\                  Ends Here                  /!\/!\/!\    #
        ######################################################################

    popd

    HANDLED="yes"
fi
