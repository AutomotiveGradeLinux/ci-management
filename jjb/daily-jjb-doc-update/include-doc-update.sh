#!/bin/bash
set -e 

#!/bin/bash
set -e 
set -x 
# we need a name and an email
#git config --global user.name build.automotivelinux.org
#git config --global user.email jenkins@automotivelinux.org
git config --global user.name build.automotivelinux.org
git config --global user.email jenkins@automotivelinux.org

rm -rf docs-webtemplate || true
wget https://raw.githubusercontent.com/automotive-grade-linux/docs-webtemplate/master/setupdocs.sh
mkdir docs-webtemplate
bash -x setupdocs.sh --directory=docs-webtemplate --webtemplate-ref=master --doctools-ref=master
# Todo --baseurl=/upload/ci/20018
cd docs-webtemplate
make build