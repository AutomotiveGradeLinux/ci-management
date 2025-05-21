#!/bin/bash

#set -x
set -e

mkdir -p ~/bin/ || true
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH=$PATH:~/bin/

# construct upload folder


BRANCH=${RELEASE_BRANCH}
REVISION=${RELEASE_VERSION}


rm -rf AGLRELEASE || true

mkdir agl-${BRANCH}-${REVISION}
pushd agl-${BRANCH}-${REVISION}

repo init  --repo-branch=repo-1 --reference=/opt/AGL/preclone -q -b ${GERRIT_BRANCH} -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo -m ${BRANCH}_${REVISION}.xml

repo sync --force-sync

repo manifest -r > ../${BRANCH}_${REVISION}.tar.xml

rm -rf .repo
find . -name *.git | xargs rm -rf

ln -sf meta-agl/README-AGL.md

cat <<EOF > aglsetup.sh
#!/bin/bash

source ./meta-agl/scripts/aglsetup.sh \$@
EOF

chmod a+x aglsetup.sh

popd

tar -cjvf agl-${BRANCH}-${REVISION}.tar.bz2 agl-${BRANCH}-${REVISION}

md5sum agl-${BRANCH}-${REVISION}.tar.bz2 > agl-${BRANCH}-${REVISION}.tar.bz2.md5sum
sha256sum agl-${BRANCH}-${REVISION}.tar.bz2 > agl-${BRANCH}-${REVISION}.tar.bz2.sha256sum



rm -rf UPLOAD || true
mkdir -p UPLOAD/

cp -ar agl-${RELEASE_BRANCH}-${RELEASE_VERSION}.* UPLOAD/

export RSYNCSRC=$(pwd)/UPLOAD
export RSYNCDST="/srv/download/AGL/release/${RELEASE_BRANCH}/"

ls -alh UPLOAD/

if test x"yes" = x"${UPLOAD}" ; then
   set +x
   ssh -o StrictHostKeyChecking=no jenkins-slave@10.30.72.8 "mkdir -p ${RSYNCDST}"
   rsync -avr -e "ssh -o StrictHostKeyChecking=no" ${RSYNCSRC}/* jenkins-slave@10.30.72.8:${RSYNCDST}
   ssh -o StrictHostKeyChecking=no jenkins-slave@10.30.72.8 "rm -rf ${RSYNCDST}/latest" 
   ssh -o StrictHostKeyChecking=no jenkins-slave@10.30.72.8 "ln -sf ${RELEASE_VERSION} ${RSYNCDST}/latest"
fi
