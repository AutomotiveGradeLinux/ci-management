#!/bin/bash
#set -x
function usage () {

echo "Usage: $0 ChangeID PatchID"
echo "       LAVA credentials are in ~/.lava-cimanagement.cfg"

}

if [[ -z $1 ]] || [[ -z $2 ]] ; then 
  usage
  exit 1
fi

export MACHINE=raspberrypi3

export GERRIT_CHANGE_NUMBER=$1
export GERRIT_PATCHSET_NUMBER=$2

# the file needs to entries:
# export LAB_AGL_USER=
# export LAB_AGL_TOKEN=
#  or
# export LAB_BAYLIBRE_USER=
# export LAB_BAYLIBRE_TOKEN=
if [[ -f ~/.lava-cimanagement.cfg ]] ; then
  source ~/.lava-cimanagement.cfg
else
  echo "you need ~/.lava-cimanagement.cfg"
fi

#set -x
set -e
export COMMON="$(pwd)/../common"

source ${COMMON}/include-agl-header.sh
source ${COMMON}/include-agl-repo.sh
source ${COMMON}/include-agl-select.sh
source ${COMMON}/include-agl-run-test-prepare.sh
source ${COMMON}/include-agl-lava-labs-prepare.sh
source ${COMMON}/include-agl-run-test-short.sh
source ${COMMON}/include-agl-lava-jobs-submit.sh
