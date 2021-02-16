#!/bin/bash
# vim: sw=2 ts=2 sts=2 et :

set -x

sudo su -c "echo 'Acquire::Check-Valid-Until no;' > /etc/apt/apt.conf.d/99no-check-valid-until"

sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com 8B48AD6246925553 || true

# go
sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com F6BC817356A3D45E || true

sudo su -c "sed -i 's;http://archive.debian.org/debian;http://deb.debian.org/debian;' /etc/apt/sources.list"
sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com 7638D0442B90D010 || true

# UPDATE things
sed -i -e "s,xenial,bionic,g" /etc/apt/sources.list

sync

cat /etc/apt/sources.list

# Make sure that we aren't using the vexxhost mirrors as they have issues
echo "---> Removing Vexxhost Ubuntu mirrors"
sed -i 's/ubuntu.mirror.vexxhost.com/us.archive.ubuntu.com/g' /etc/apt/sources.list

cat /etc/apt/sources.list

DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -y -u dist-upgrade

DEBIAN_FRONTEND=noninteractive dpkg --configure -a 

DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get -y install wget python python3 python-pip zip unzip iperf3 \
		       debian-keyring debian-archive-keyring \
		       python3-pip
DEBIAN_FRONTEND=noninteractive apt-get clean

DEBIAN_FRONTEND=noninteractive apt-get install linux-image-4.15.0-123-generic

DEBIAN_FRONTEND=noninteractive apt full-upgrade


# Adding stretch-backports for lavacli
#echo "deb http://deb.debian.org/debian stretch-backports main" >> /etc/apt/sources.list
#DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y -t stretch-backports lavacli

sudo pip3 install --upgrade pip
sudo pip3 install --upgrade --force-reinstall lavacli==1.0

# we have a build blocker wrt useradd - I assume it is caused by /bin/sh being dash
# systemd: Performing useradd with
echo "dash dash/sh boolean false" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

#cat <<EOFHOSTS >> /etc/hosts
# workaround for download
#10.30.72.8 download.automotivelinux.org
10.30.72.8 download-internal.automotivelinux.org
#EOFHOSTS

# install newer version of jjb ... fixes issues with rendering
sudo pip3 install --upgrade --force-reinstall -v jenkins-job-builder

cat <<EOFSYSCTL >> /etc/sysctl.conf
# we have a lot of make jobs, this helps a lot
kernel.sched_child_runs_first = 1
# smooth over a lot of I/O requests and do less blocking
vm.dirty_background_bytes = 0
vm.dirty_background_ratio = 75
vm.dirty_expire_centisecs = 4320000
vm.dirtytime_expire_seconds = 432000
vm.dirty_bytes = 0
vm.dirty_ratio = 90
vm.dirty_writeback_centisecs = 0

# disable ipv6
net.ipv6.conf.all.disable_ipv6 = 1

EOFSYSCTL

# releng-scripts needs latest (stable v2.9) jinja2
sudo pip install --force-reinstall --ignore-installed jinja2
sudo pip install --upgrade jinja2
sudo pip3 install --force-reinstall --ignore-installed jinja2
sudo pip3 install --upgrade jinja2

# updates for cloud-init
sudo pip3 install --upgrade oauthlib
sudo pip3 install --upgrade configobj>=5.0.2
sudo pip3 install --upgrade pyyaml
sudo pip3 install --upgrade requests
sudo pip3 install --upgrade jsonschema
sudo pip3 install --upgrade jsonpatch


python -c "import sys; print sys.path"

sudo pip show jinja2
sudo pip3 show jinja2

# install go for xds build


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


exit 0
