#!/bin/bash


#

echo "Run: dpkg-reconfigure openssh-server"
echo "Fixup /etc/ssh/sshd_config"
echo "Run: ssh -R HOST:2222:localhost:22 user@10.0.2.2"
echo "Then connect to HOST:2222 with ssh"

qemu-system-x86_64 -vnc :0 -hda output_ubuntu/jenkins-new-test -net nic -net user -serial stdio -accel kvm -smp 2 -m 4096