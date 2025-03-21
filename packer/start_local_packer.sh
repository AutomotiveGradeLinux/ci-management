#!/bin/bash

set -x
#

#echo "Run: dpkg-reconfigure openssh-server"
#echo "Fixup /etc/ssh/sshd_config"
#echo "Run: ssh -R HOST:2222:localhost:22 user@10.0.2.2"
#echo "Then connect to HOST:2222 with ssh"

#qemu-system-x86_64 -hda output_ubuntu/jenkins-new-test -net nic -net user,hostfwd=tcp:127.0.0.1:60022-:22 -accel kvm -smp 4 -m 8192 -nographic
qemu-system-x86_64 -hda output_ubuntu/jenkins-new-test.raw -hdb output_ubuntu/file.img -net nic -net user,hostfwd=tcp:127.0.0.1:60022-:22 -accel kvm -smp 24 -m 32768 -nographic
