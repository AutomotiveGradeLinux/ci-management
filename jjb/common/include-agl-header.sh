#!/bin/bash
# (c) 2016 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2
#
# debugging purposes
set -e

################################################################################
## Header
################################################################################


# VARIABLES
OPTIND=1
#export DLHOST="http://download.automotivelinux.org/"
# DLHOST in auto.conf
export NOGFX=false
export VERBOSE=false
export DEBUG=false
function vprint() {
    :
}
function dprint() {
    :
}

# defaults for project, branch, refspec
export TARGETPROJECT="AGL/AGL-repo"
export TARGETBRANCH="master"
export TARGETREFSPEC="refs/heads/master"

export TARGETFEATURESnogfx="agl-ci-change-features-nogfx"
export TARGETFEATURES="agl-ci-change-features"

export TARGETQA=""
export TARGETIMAGE="agl-demo-platform\${TARGETQA}"
export TARGETIMAGEnogfx="agl-image-ivi-crosssdk"

export TARGETSDKIMAGE="agl-demo-platform-crosssdk"


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

if test x"" = x"${MACHINE}"; then
    export MACHINE="qemux86-64"
fi

# finally cmdline arguments
while getopts ":b:i:p:r:dnqvx" opt; do
    case "$opt" in
	b)
	    export TARGETBRANCH="$OPTARG"
	    ;;
	d)
	    DEBUG=true
	    function dprint() {
		echo "DEBUG: $@"
	    }
	    ;;
	i)
	    export TARGETIMAGE="$OPTARG"
	    ;;
	n)
	    export NOGFX=true
	    ;;
	p)
	    export TARGETPROJECT="$OPTARG"
	    ;;
	q)
	    export TARGETQA="-qa"
	    ;;
	r)
	    export TARGETREFSPEC="$OPTARG"
	    ;;
	v)
	    VERBOSE=true
	    function vprint() {
		echo "VERBOSE: \"$@\""
	    }
	    ;;
	x)
	    set -x
	    ;;
	h|\?)
	    echo "$0 [-h/-?] -bdinpqrvx"
	    echo "--------------------------------------------------------------------------------"
	    echo "  -b <branch>  - name of the branch to use          (default=master)"
	    echo "  -d           - debug"
	    echo "  -i <image>   - name of the image to build         (default=agl-demo-platform)"
	    echo "  -n           - no graphics (no wayland, aka no drivers)"
	    echo "  -p <project> - project to use                     (default=AGL/AGL-repo)"
	    echo "  -q           - build '*-qa' images                (default='')"
	    echo "  -r <refspec> - refspec to use                     (default=refs/heads/master)"
	    echo "  -v           - verbose"
	    echo "  -x           - set -x"
	    echo "--------------------------------------------------------------------------------"
	    echo "  GERRIT_PROJECT, GERRIT_BRANCH, GERRIT_REFSPEC are used if present,"
	    echo "  but cmdline arguments take precedence."
	    echo "--------------------------------------------------------------------------------"
	    exit 1
	    ;;
	:)
	    echo "Option -$OPTARG required an argument."
	    exit 1
	    ;;
    esac
done

# expand
eval TARGETIMAGE="$TARGETIMAGE"
eval TARGETIMAGEnogfx="$TARGETIMAGEnogfx"

# The 'real' machine name
export TARGETMACHINE=${MACHINE}

# bail out if we're not the 'BUILDONLY' machine
if test -n "${BUILDONLY}" ; then
    if test x"ignore" != x"${BUILDONLY}" ; then
	if test x"${MACHINE}" != x"${BUILDONLY}" ; then
	    echo "Skipping ${MACHINE} as BUILDONLY is ${BUILDONLY}."
	    exit 1
	fi
    fi
fi

# The exceptions
if $NOGFX; then
    export TARGETIMAGE=${TARGETIMAGEnogfx}
    export TARGETFEATURES="${TARGETFEATURESnogfx}"
fi
# porter-nogfx means no graphic drivers
if test x"porter-nogfx" = x"$MACHINE"; then
    export TARGETIMAGE=${TARGETIMAGEnogfx}
    export TARGETFEATURES="${TARGETFEATURESnogfx}"
    export TARGETMACHINE="porter"
    export TARGETSDKIMAGE="agl-image-ivi-crosssdk"
fi
# m3ulcb-nogfx means no graphic drivers
if test x"m3ulcb-nogfx" = x"$MACHINE"; then
    export TARGETIMAGE=${TARGETIMAGEnogfx}
    export TARGETFEATURES="${TARGETFEATURESnogfx}"
    export TARGETMACHINE="m3ulcb"
    export TARGETSDKIMAGE="agl-image-ivi-crosssdk"
fi
set -x
# h3ulcb-nogfx means no graphic drivers
if test x"h3ulcb-nogfx" = x"$MACHINE"; then
    export TARGETIMAGE=${TARGETIMAGEnogfx}
    if test x"master" = x"${TARGETBRANCH}" ; then
        export TARGETFEATURES="${TARGETFEATURESnogfx} agl-refhw-h3"
    else
        export TARGETFEATURES="${TARGETFEATURESnogfx}"
    fi
    export TARGETMACHINE="h3ulcb"
    export TARGETSDKIMAGE="agl-image-ivi-crosssdk"
fi
set +x

if test x"raspberrypi4" = x"${MACHINE}" -a x"master" = x"${TARGETBRANCH}" ; then
    export TARGETMACHINE="raspberrypi4-64"
fi
if test x"raspberrypi4" = x"${MACHINE}" -a x"jellyfish" = x"${TARGETBRANCH}" ; then
    export TARGETMACHINE="raspberrypi4-64"
fi

#if $DEBUG; then
set | grep ^TARGET || true
set | grep ^GERRIT || true
set | grep ^MACHINE || true
#fi

# to avoid .gitconfig.lock race condition do
sleep $((1 + RANDOM % 10))

if test ! -f ~/.gitconfig ; then 
  git config --global user.email "jenkins-dontreply@build.automotivelinux.org"
  git config --global user.name "jenkins-dontreply@build.automotivelinux.org"
fi
