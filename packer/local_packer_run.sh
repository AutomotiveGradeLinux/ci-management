#!/bin/bash
packer fix -var-file=vars/ubuntu-16.04.json -var-file=vars/cloud-env.json templates/basebuild-local-kvm.json > templates/basebuild-local-kvm-new.json
mv templates/basebuild-local-kvm-new.json templates/basebuild-local-kvm.json
packer build -var-file=vars/ubuntu-16.04.json -var-file=vars/cloud-env.json templates/basebuild-local-kvm.json 
