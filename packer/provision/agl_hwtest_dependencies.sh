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
		       python3-pip python3-yaml
DEBIAN_FRONTEND=noninteractive apt-get clean

# Adding stretch-backports for lavacli
#echo "deb http://deb.debian.org/debian stretch-backports main" >> /etc/apt/sources.list
#DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y -t stretch-backports lavacli

pip3 install lavacli

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
sudo pip install --upgrade --force-reinstall -v jenkins-job-builder

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

# fix for cloud-init
pip3 install --upgrade jsonpatch
pip3 install --upgrade cloudinit

python -c "import sys; print sys.path"

sudo pip show jinja2
sudo pip3 show jinja2

# install go for xds build

exit 0
