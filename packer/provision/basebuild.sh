#!/bin/bash -x
# vim: set tw=4 sw=4 sts=4 et :

# Presently nothing to do

set -x

mkdir -p /mnt/tank
chown -R jenkins:jenkins /mnt/tank
mkdir -p /mnt/tank2
chown -R jenkins:jenkins /mnt/tank2

cat <<EOFSTAB >> /etc/fstab

# tmp should be tmpfs so gcc tmpfiles do not hit the disk
none /tmp tmpfs defaults 0 0

#10.30.73.73:/srv/tank /mnt/tank  nfs vers=3,x-systemd.mount-timeout=5,x-systemd.device-timeout=5,auto,async,nofail,noatime,nolock,rsize=8192,wsize=8192,sec=sys,intr,_netdev 0 0
#10.30.73.73:/srv/tank /mnt/tank2 nfs vers=3,x-systemd.mount-timeout=5,x-systemd.device-timeout=5,auto,async,nofail,noatime,nolock,rsize=8192,wsize=8192,sec=sys,intr,_netdev 0 0
10.30.73.73:/srv/tank /mnt/tank  nfs auto,vers=3,nofail,noatime,intr,actimeo=1800,async,rsize=8192,wsize=8192,sec=sys,_netdev 0 0
10.30.73.73:/srv/tank /mnt/tank2 nfs auto,vers=3,nofail,noatime,nolock,intr,tcp,actimeo=1800,_netdev 0 0
#                                    vers=3,auto,nofail,noatime,nolock,intr,tcp,actimeo=1800

EOFSTAB

