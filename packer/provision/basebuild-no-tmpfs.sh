#!/bin/bash -x
# vim: set tw=4 sw=4 sts=4 et :

# Presently nothing to do

set -x


sudo su -c "echo 'Acquire::Check-Valid-Until no;' > /etc/apt/apt.conf.d/99no-check-valid-until"


sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com 8B48AD6246925553 || true

# go
sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com F6BC817356A3D45E || true

sudo su -c "sed -i 's;http://archive.debian.org/debian;http://deb.debian.org/debian;' /etc/apt/sources.list"
sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com 7638D0442B90D010 || true

cat /etc/apt/sources.list

# Make sure that we aren't using the vexxhost mirrors as they have issues
echo "---> Removing Vexxhost Ubuntu mirrors"
sed -i 's/ubuntu.mirror.vexxhost.com/us.archive.ubuntu.com/g' /etc/apt/sources.list

# UPDATE things
sed -i -e "s,xenial,bionic,g" /etc/apt/sources.list

sync

cat /etc/apt/sources.list

DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -y -u dist-upgrade

DEBIAN_FRONTEND=noninteractive dpkg --configure -a

DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get -y install debian-keyring debian-archive-keyring python3-pip python-pip apt

DEBIAN_FRONTEND=noninteractive apt-get clean
# new kernel
DEBIAN_FRONTEND=noninteractive apt-get install linux-image-4.15.0-123-generic
# java for jenkins and unzip to extract packer
DEBIAN_FRONTEND=noninteractive apt-get install  default-jre-headless default-jdk-headless unzip

DEBIAN_FRONTEND=noninteractive apt full-upgrade


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

mkdir -p /home/jenkins/.ssh
mkdir /w
cp -r /home/ubuntu/.ssh/authorized_keys /home/jenkins/.ssh/authorized_keys

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD0EqO61Im8/zCKj4Hg/H26Q3Z4UAjlIePVVu54LfbCIJ7wPLNTBBXBz74cTuiUMF8CbeBwOyWR83NELbSllKnr+wK6pv3h6f7Zn54sQBXjIy11K38CdrMdXxaCIIPBGqJvOy2JukdKuuwfTuXjUk57evoXKJH1aw3Vu3+81gvqCdKlzbWlOP1p0MdvsWVRpOMn27IH2Gz4/nDdwWtIF8YFHAIbWmlCZGiv8/i/nyuLfsC7p6p00qHfxO5KFTsstQe+/f8WkGNaY/Vz124PBic51GsJ+2SfEnDvYSaQvjsf+xPsfQ4Bo6xkz75sN3PYuNOGZX2TQom139b2x18XXzgwSzeZwYhPKN511xBFll5/0/SugWWU+7pNtXUrK+1PZ7zshlch/vaIJzeZCYYRim0yUDM6rLiJ/zqMRO5jvPqpnFjZ9Rz+bqPpLC3mMiEWBdbs9Hxtx3+NhrFVBGlDVoi7sBzDKyrSnuljAZHLaT9rxQquhWLKRUjPZviSb8s544WaQmWDyOTWkPXdN63pVM23EAfi1wVRIyPcLZMdoHQohbh+ePclG2pGfV8hro+aDNyvLcXj1wL8p43elV4d/jPjsePqso7IhyPSghhLCO7lLnrlNVBaI5A+/iUILRHU3LlmKJlErwDmkl1XAJbO0DHDpSwsIDrK1q9Eb7e+C6M8Ww==" >> /home/jenkins/.ssh/authorized_keys
chmod 0600 /home/jenkins/.ssh/authorized_keys

# Generate ssh key for use by Robot jobs
echo -e 'y\n' | ssh-keygen -N "" -f /home/jenkins/.ssh/id_rsa -t rsa
chown -R jenkins:jenkins /home/jenkins/.ssh /w


