#!/bin/bash
# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
##############################################################################
# Copyright (c) 2016 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################

#######################
# Create Jenkins User #
#######################

OS=$(facter operatingsystem | tr '[:upper:]' '[:lower:]')

useradd -m -s /bin/bash jenkins

# Check if docker group exists
grep -q docker /etc/group
if [ "$?" == '0' ]
then
  # Add jenkins user to docker group
  usermod -a -G docker jenkins
fi

# Check if mock group exists
grep -q mock /etc/group
if [ "$?" == '0' ]
then
  # Add jenkins user to mock group so they can build Int/Pack's RPMs
  usermod -a -G mock jenkins
fi

mkdir /home/jenkins/.ssh
mkdir /w
cp -r /home/${OS}/.ssh/authorized_keys /home/jenkins/.ssh/authorized_keys

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD0EqO61Im8/zCKj4Hg/H26Q3Z4UAjlIePVVu54LfbCIJ7wPLNTBBXBz74cTuiUMF8CbeBwOyWR83NELbSllKnr+wK6pv3h6f7Zn54sQBXjIy11K38CdrMdXxaCIIPBGqJvOy2JukdKuuwfTuXjUk57evoXKJH1aw3Vu3+81gvqCdKlzbWlOP1p0MdvsWVRpOMn27IH2Gz4/nDdwWtIF8YFHAIbWmlCZGiv8/i/nyuLfsC7p6p00qHfxO5KFTsstQe+/f8WkGNaY/Vz124PBic51GsJ+2SfEnDvYSaQvjsf+xPsfQ4Bo6xkz75sN3PYuNOGZX2TQom139b2x18XXzgwSzeZwYhPKN511xBFll5/0/SugWWU+7pNtXUrK+1PZ7zshlch/vaIJzeZCYYRim0yUDM6rLiJ/zqMRO5jvPqpnFjZ9Rz+bqPpLC3mMiEWBdbs9Hxtx3+NhrFVBGlDVoi7sBzDKyrSnuljAZHLaT9rxQquhWLKRUjPZviSb8s544WaQmWDyOTWkPXdN63pVM23EAfi1wVRIyPcLZMdoHQohbh+ePclG2pGfV8hro+aDNyvLcXj1wL8p43elV4d/jPjsePqso7IhyPSghhLCO7lLnrlNVBaI5A+/iUILRHU3LlmKJlErwDmkl1XAJbO0DHDpSwsIDrK1q9Eb7e+C6M8Ww==" >> /home/jenkins/.ssh/authorized_keys
chmod 0600 /home/jenkins/.ssh/authorized_keys

# Generate ssh key for use by Robot jobs
echo -e 'y\n' | ssh-keygen -N "" -f /home/jenkins/.ssh/id_rsa -t rsa
chown -R jenkins:jenkins /home/jenkins/.ssh /w
