#!/bin/bash

curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python3 get-pip.py --user
export PATH=/home/jenkins/.local/bin:$PATH

pip3 install --user jenkins-job-builder

jenkins-jobs update --delete-old --recursive jjb/

# Submit patches for any jobs that can be auto updated
function submitJJB {
    git commit -asm "Update automated project templates"
    git push origin HEAD:refs/for/master
}

gitdir=$(git rev-parse --git-dir); scp -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -p -P 29418 agl-jobbuilder@gerrit.automotivelinux.org:hooks/commit-msg ${gitdir}/hooks/
git diff --exit-code || submitJJB
