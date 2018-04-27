#!/bin/bash

#set -x
set -e

echo -e "\n\n\n"
echo "#########################################"
echo -e "\n\n\n"

export RSYNCDST="/srv/download/AGL/upload/ci/${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER}/"
export RSYNCSRC=$(pwd)/UPLOAD/*
LANG=C tree $RSYNCSRC
ssh -o StrictHostKeyChecking=no jenkins-slave@10.30.72.8 mkdir -p ${RSYNCDST}
rsync -avr --inplace -L -e "ssh -o StrictHostKeyChecking=no" $RSYNCSRC jenkins-slave@10.30.72.8:$RSYNCDST
