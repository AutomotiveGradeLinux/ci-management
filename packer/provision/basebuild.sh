#!/bin/bash -x
# vim: set tw=4 sw=4 sts=4 et :

# Presently nothing to do

set -x

mkdir -p /srv/tank
chown -R jenkins:jenkins /srv/tank

cat <<EOFSTAB >> /etc/fstab

# tmp should be tmpfs so gcc tmpfiles do not hit the disk
none /tmp tmpfs defaults 0 0

10.30.73.73:/srv/tank /mnt/tank nfs vers=3,auto,async,nofail,noatime,nolock,rsize=8192,wsize=8192,sec=sys,intr 0 0
#                                    vers=3,auto,nofail,noatime,nolock,intr,tcp,actimeo=1800

EOFSTAB

