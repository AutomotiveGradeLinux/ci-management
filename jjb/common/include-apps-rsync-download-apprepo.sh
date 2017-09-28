#!/bin/bash

#set -x
set -e

echo -e "\n\n\n"
echo "#########################################"
echo -e "\n\n\n"
#                                       project branch date(latest)
export RSYNCDST="/srv/download/AGL/apps/"
export RSYNCSRC=$(pwd)/UPLOAD/
LANG=C tree $RSYNCSRC

set

exit 0
ssh -o StrictHostKeyChecking=no jenkins-slave@10.30.72.8 mkdir -p ${RSYNCDST}
rsync -avr -l --copy-unsafe-links -e "ssh -o StrictHostKeyChecking=no" $RSYNCSRC jenkins-slave@10.30.72.8:$RSYNCDST
