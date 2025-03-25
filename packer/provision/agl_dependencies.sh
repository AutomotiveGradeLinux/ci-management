#!/bin/bash
# vim: sw=2 ts=2 sts=2 et :
#set -e
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
sed -i -e "s,xenial,focal,g" /etc/apt/sources.list
sync
cat /etc/apt/sources.list

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get --purge remove  plymouth-theme* plymouth
DEBIAN_FRONTEND=noninteractive apt-get autoremove
DEBIAN_FRONTEND=noninteractive apt-get apt-get -y -u dist-upgrade
DEBIAN_FRONTEND=noninteractive dpkg --configure -a

DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get -y install gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat \
                       libsdl1.2-dev xterm make xsltproc docbook-utils fop dblatex xmlto autoconf automake \
                       libtool libglib2.0-dev libarchive-dev python-git git python python-minimal repo \
                       tree rsync python-yaml python-requests curl tar docker.io pandoc python3 \
                       ruby-all-dev ruby-ffi ruby-ffi-* jekyll ruby-redcarpet mkdocs \
                       python-pip python-simplejson g++-multilib make zip unzip iperf3 \
                       debian-keyring debian-archive-keyring python3-yaml python3-pip python-pip apt \
                       liblz4-tool zstd docker.io git diffstat unzip texinfo gcc build-essential \
                       chrpath socat cpio python3 python3-pip python3-pexpect xz-utils debianutils \
                       iputils-ping python3-git python3-jinja2 libegl1-mesa libsdl1.2-dev pylint3 \
                       xterm python3-subunit mesa-common-dev zstd liblz4-tool



DEBIAN_FRONTEND=noninteractive apt-get clean
#DEBIAN_FRONTEND=noninteractive apt-get -y install linux-image-4.15.0-123-generic
DEBIAN_FRONTEND=noninteractive apt full-upgrade


sudo pip3 install --upgrade pip
sudo pip3 install --upgrade --force-reinstall --ignore-installed pyyaml
sudo pip3 install --upgrade --ignore-installed --force-reinstall lavacli==1.0

# we have a build blocker wrt useradd - I assume it is caused by /bin/sh being dash
# systemd: Performing useradd with
echo "dash dash/sh boolean false" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# add user ubuntu to docker group:
sudo usermod -a -G docker ubuntu
sudo usermod -a -G docker jenkins

cat <<EOFHOSTS >> /etc/hosts

# workaround for download
10.30.72.8 download.automotivelinux.org
10.30.72.8 download-internal.automotivelinux.org
127.0.0.1 ubuntu-16

EOFHOSTS

# install newer version of jjb ... fixes issues with rendering
sudo pip install --upgrade --force-reinstall -v jenkins-job-builder

# let the upgrade run anyway
rm -rf /var/run/reboot-requir*

DEBIAN_FRONTEND=noninteractive do-release-upgrade -f DistUpgradeViewNonInteractive --mode=server


cat <<EOFSYSCTL >> /etc/sysctl.conf
# we have a lot of make jobs, this helps a lot
kernel.sched_child_runs_first = 1
# smooth over a lot of I/O requests and do less blocking
vm.dirty_background_bytes = 0
vm.dirty_background_ratio = 20
vm.dirty_expire_centisecs = 4320000
vm.dirtytime_expire_seconds = 432000
vm.dirty_bytes = 0
vm.dirty_ratio = 80
vm.dirty_writeback_centisecs = 0

# disable ipv6
net.ipv6.conf.all.disable_ipv6 = 1

EOFSYSCTL

mkdir -p /opt/AGL
cd /opt/AGL/

git clone https://git.automotivelinux.org/AGL/documentation
cd documentation
sudo pip3 install -r requirements.txt

# python markdown linter
sudo pip3 install mdlint

# releng-scripts needs latest (stable v2.9) jinja2
sudo pip install --force-reinstall --ignore-installed jinja2
sudo pip install --upgrade jinja2
sudo pip install --force-reinstall --ignore-installed PyYAML
sudo pip install --upgrade PyYAML

sudo pip3 install --force-reinstall --ignore-installed jinja2
sudo pip3 install --upgrade jinja2
sudo pip3 install --force-reinstall --ignore-installed PyYAML
sudo pip3 install --upgrade PyYAML


# updates for cloud-init
sudo pip3 install --upgrade oauthlib
sudo pip3 install --upgrade configobj>=5.0.2
sudo pip3 install --upgrade requests
sudo pip3 install --upgrade jsonschema
sudo pip3 install --upgrade jsonpatch

python -c "import sys; print sys.path"

. /etc/os-release

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
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDFPlD8r/AP4CJMwaaiBufxWYBL+H4t2Q7c7uRsFgrRZTPWILayNlUbz2SnJMOGw9/Fxj6pO5DudiV0qp/D9mSb5Ai1u3Fd0Ev7cUKGZ3UlnvLQX6N/42GpshmPbLMEj8GxRK7YgS9B8XgsPZALsoFBTv2PE7984tRO8SOq2Ijh13Vxfh9sz6rPm3sJZJ8zyFOnpBbEPcmN/OkbRQEwcMt1JXw/iEHvo9/pAUHBD9ZF4dAzAym3AqjxwkNy6oFsebdl3Czi41GLX+wj389gAW+YmT5MpHQae4aKkfc+3LkpXY5Od43lOBmBpXWMDV4JxL5Am4BiXQHkRuHr/4a3Q7TEKSpeUmcKusJR4j8hkIwxgqBYLwhJic5GkMrsu+223IH42M+yKXlzij9WBl8YIh1l+lma9ogQknMhb+2yJjiY2eeLAnF31NSA8EiHDQRwvbJBsC4d5RyCFpV3Kd9wX2UzpMfqRIQD7qFDOZzmSGjhLX9jpsQYHhobc/iK//Cy300= dl9pf@legolas"  >> /home/jenkins/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDxIHhWB+wX7j7n3tXH4jfBF0kmPZtjzuudp3jsRTNz1ddL9A6CH6GH+aP+9ps7/y8KQrxzU169b9mDHFM9Wq6hetfFEjJk+4JJLPlHWwznSzDIDz0nTkH9Yp8LvTCjIz1mg9PZsZTM47zxmthhdmVegBbQDEDNBWwdUHiziDF9/4EmDYn+//U9CU8vCuVqM4atnHVtCA+2iVkavvXiEfL75SHmqsB4psRQ1mZOWJkGefJXbh2gkEuuhEno1XW3Txc3Gt/hmzVR4h+2iBuxVcCEFNaKqJhbDOn5nG50rFuZj6gkRbtVnV6XKXI4AznPTuWhPtDTmsBHSAuLx/EiWho69L0Gh3adaSD0o0IvcgzN2m9fmKMLKmDKAlLGVhxZhqIFRiTshw0lTjdrk59TTTXDh6cA4hQ2c20bknXgjdegc0W2ef9fiTFfLKmY5rD2RFvKdGBWlGH8WVU86QzcZeyvFGGHtZ9AgSmIyDpWFwjcCXmxl1okGeBF2pJUovp0SEU= dl9pf@elrond"  >> /home/jenkins/.ssh/authorized_keys
chmod 0600 /home/jenkins/.ssh/authorized_keys

# Generate ssh key for use by Robot jobs
echo -e 'y\n' | ssh-keygen -N "" -f /home/jenkins/.ssh/id_rsa -t rsa
chown -R jenkins:jenkins /home/jenkins/.ssh /w

sudo chown -R ubuntu:ubuntu /home/ubuntu 


# gitlab-runner
cat <<EOF | sudo tee /etc/apt/preferences.d/pin-gitlab-runner.pref
Explanation: Prefer GitLab provided packages over the Debian native ones
Package: gitlab-runner
Pin: origin packages.gitlab.com
Pin-Priority: 1001
EOF

curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash

DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install gitlab-runner

# workaround for missing file that made pip bail out
sudo touch /usr/local/lib/python3.6/dist-packages/PyYAML-6.0.dist-info/METADATA || true



exit 0
