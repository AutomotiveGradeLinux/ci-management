#!/bin/bash
curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py"
python3 get-pip.py --user
export PATH=/home/jenkins/.local/bin:$PATH

pip3 install --user jenkins-job-builder

ls -alh
jenkins-jobs test --recursive jjb/
