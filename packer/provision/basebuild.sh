#!/bin/bash -x
# vim: set tw=4 sw=4 sts=4 et :

# Presently nothing to do

set -x

cat <<EOFSTAB >> /etc/fstab

# tmp should be tmpfs so gcc tmpfiles do not hit the disk
none /tmp tmpfs defaults 0 0

10.30.73.73:/srv/tank /mnt/tank nfs4 auto,x-systemd.automount,async,rsize=8192,wsize=8192,sec=sys,intr 0 0

EOFSTAB

mkdir -p /srv/tank