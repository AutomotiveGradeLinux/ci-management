#!/bin/bash

#set -x
export AGLBRANCH=master
export GERRIT_REFSPEC="refs/changes/51/9551/2"
export GERRIT_PROJECT="src/xds/xds-server"
export GERRIT_CHANGE_NUMBER="10799"
export GERRIT_PATCHSET_NUMBER="1"
export GERRIT_PATCHSET_REVISION="1a1ff962da92aff5a1d3e757710c725e03238458"
export GERRIT_HOST="gerrit.automotivelinux.org"
export GERRIT_PORT="29418"
export PROJECT_TO_BUILD="xds-server"

export -p > env.save

# TBI

source env.save

#. ../common/include-xds-header.sh
#. ../common/include-xds-build-common.sh

done