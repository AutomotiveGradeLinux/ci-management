#!/bin/bash
# vim: sw=2 ts=2 sts=2 et :

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
    apt-get -y install gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat \
                       libsdl1.2-dev xterm make xsltproc docbook-utils fop dblatex xmlto autoconf automake \
                       libtool libglib2.0-dev libarchive-dev python-git git python python-minimal repo \
                       tree rsync python-yaml python-requests curl tar docker.io pandoc python3 \
                       ruby-all-dev ruby-ffi ruby-ffi-* jekyll ruby-redcarpet mkdocs \
                       python-pip python-simplejson g++-multilib make zip unzip iperf3 \
                       debian-keyring debian-archive-keyring python3-yaml python3-pip python-pip apt

DEBIAN_FRONTEND=noninteractive apt-get clean

DEBIAN_FRONTEND=noninteractive apt-get install linux-image-4.15.0-123-generic

DEBIAN_FRONTEND=noninteractive apt full-upgrade

# Adding stretch-backports for lavacli
#echo "deb https://apt.lavasoftware.org/release buster-backports main" >> /etc/apt/sources.list

#wget https://apt.lavasoftware.org/lavasoftware.key.asc
#sudo apt-key add lavasoftware.key.asc
#rm lavasoftware.key.asc
#sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com A791358F2E49B100

#DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y lavacli

sudo pip3 install --upgrade pip
sudo pip3 install --upgrade --force-reinstall lavacli==1.0

# we have a build blocker wrt useradd - I assume it is caused by /bin/sh being dash
# systemd: Performing useradd with
echo "dash dash/sh boolean false" | debconf-set-selections
DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# add user ubuntu to docker group:
sudo usermod -a -G docker ubuntu

cat <<EOFHOSTS >> /etc/hosts

# workaround for download
10.30.72.8 download.automotivelinux.org
10.30.72.8 download-internal.automotivelinux.org

EOFHOSTS

# install newer version of jjb ... fixes issues with rendering
sudo pip install --upgrade --force-reinstall -v jenkins-job-builder

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

### webdocs + xds
# taken from container setup script. not documented in readme.
# install node.js and tools (npm, gulp, bower)
#
curl -v --connect-timeout 60 --retry 3 -sL https://deb.nodesource.com/setup_12.x | bash -
DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
which -a npm
dpkg -L nodejs
npm install --global gulp bower

################### SDX181207 { - obsolete: section until closing brace should be removed after migration to next docsite
# tools used to generate developer website (https://github.com/automotive-grade-linux/docs-agl)
#gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
#    && curl -sSL https://get.rvm.io | bash -s stable --ruby --gems=jekyll


mkdir -p /opt/AGL
cd /opt/AGL/

git clone https://git.automotivelinux.org/AGL/documentation
cd documentation
sudo pip3 install -r requirements.txt

# ruby markdown linter
#sudo gem install mdl

# python markdown linter
sudo pip3 install mdlint

# releng-scripts needs latest (stable v2.9) jinja2
sudo pip install --force-reinstall --ignore-installed jinja2
sudo pip install --upgrade jinja2
sudo pip3 install --force-reinstall --ignore-installed jinja2
sudo pip3 install --upgrade jinja2

# updates for cloud-init
pip3 install --upgrade oauthlib
pip3 install --upgrade configobj>=5.0.2
pip3 install --upgrade pyyaml
pip3 install --upgrade requests
pip3 install --upgrade jsonschema
pip3 install --upgrade jsonpatch

python -c "import sys; print sys.path"

sudo pip show jinja2
sudo pip3 show jinja2

# install go for xds build

. /etc/os-release
wget -O - "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x52B59B1571A79DBC054901C0F6BC817356A3D45E" | sudo apt-key add -
sudo bash -c "cat >> /etc/apt/sources.list.d/golang.list <<EOF
deb http://ppa.launchpad.net/longsleep/golang-backports/ubuntu bionic main
EOF"
sudo apt-get update
sudo apt-get install golang-go

# Crossbuild standard go libraries for MacOS and Windows
sudo GOOS=darwin GOARCH=amd64 go install -v -a std
sudo GOOS=windows GOARCH=amd64 go install -v -a std

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
