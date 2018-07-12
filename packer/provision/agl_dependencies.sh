#!/bin/bash
# vim: sw=2 ts=2 sts=2 et :

set -x

sudo su -c "echo 'deb http://ftp.debian.org/debian jessie-backports main' >> /etc/apt/sources.list"
sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com 8B48AD6246925553

# go
sudo apt-key adv --recv-key --keyserver keyserver.ubuntu.com F6BC817356A3D45E

cat /etc/apt/sources.list

# Make sure that we aren't using the vexxhost mirrors as they have issues
echo "---> Removing Vexxhost Ubuntu mirrors"
sed -i 's/ubuntu.mirror.vexxhost.com/us.archive.ubuntu.com/g' /etc/apt/sources.list

cat /etc/apt/sources.list

DEBIAN_FRONTEND=noninteractive apt-get update && apt-get -y -u dist-upgrade

DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get -y install gawk wget git-core diffstat unzip texinfo gcc-multilib build-essential chrpath socat \
                       libsdl1.2-dev xterm make xsltproc docbook-utils fop dblatex xmlto autoconf automake \
                       libtool libglib2.0-dev libarchive-dev python-git git python python-minimal repo \
                       tree rsync python-yaml python-requests curl tar docker.io pandoc python3 \
                       ruby-all-dev ruby-ffi ruby-ffi-* jekyll ruby-redcarpet mkdocs \
                       python-pip python-simplejson g++-multilib make zip unzip

DEBIAN_FRONTEND=noninteractive apt-get install -y -t jessie-backports lava-tool=0.19-1~bpo8+1

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


EOFSYSCTL

### webdocs + xds
# taken from container setup script. not documented in readme.
# install node.js and tools (npm, gulp, bower)
#
curl -v --connect-timeout 60 --retry 3 -sL https://deb.nodesource.com/setup_8.x | bash -
DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
which -a npm
dpkg -L nodejs
npm install --global gulp bower

# tools used to generate developer website (https://github.com/automotive-grade-linux/docs-agl)
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 \
    && curl -sSL https://get.rvm.io | bash -s stable --ruby --gems=jekyll


mkdir -p /opt/AGL
cd /opt/AGL/
#mkdir webdocs
#cd webdocs
#git clone http://github.com/iotbzh/webdocs-tools
#git clone http://github.com/iotbzh/webdocs-sample
git clone https://github.com/automotive-grade-linux/docs-agl

cd ./docs-agl/doctools/webdocs/
npm install
#gem install --no-user-install -V kramdown
#gem install --no-user-install -V jekyll-plantuml

#gem install --no-user-install -V --version 3.1.6 jekyll
#gem install --no-user-install -V --version 1.13.1 kramdown

### hope that is enough

# ruby markdown linter
sudo gem install mdl

# python markdown linter
sudo pip install mdlint

# releng-scripts needs latest (stable v2.9) jinja2
sudo pip install --force-reinstall --ignore-installed jinja2
sudo pip install --upgrade jinja2

python -c "import sys; print sys.path"

sudo pip show jinja2

# install go for xds build

source /etc/os-release
wget -O - "http://keyserver.ubuntu.com/pks/lookup?op=get&search=0x52B59B1571A79DBC054901C0F6BC817356A3D45E" | sudo apt-key add -
sudo bash -c "cat >> /etc/apt/sources.list.d/golang.list <<EOF
deb http://ppa.launchpad.net/longsleep/golang-backports/ubuntu ${VERSION_CODENAME} main
EOF"
sudo apt-get update
sudo apt-get install golang-go

# Crossbuild standard go libraries for MacOS and Windows
sudo GOOS=darwin GOARCH=amd64 go install -v -a std
sudo GOOS=windows GOARCH=amd64 go install -v -a std

exit 0
