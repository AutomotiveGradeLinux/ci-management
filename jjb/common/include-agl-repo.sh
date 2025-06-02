# ## include-agl-repo.sh
# (c) 2016 Jan-Simon Moeller, dl9pf(at)gmx.de
# License: GPLv2
################################################################################
## Repo init/sync
################################################################################

set -x
mkdir -p ~/bin
curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
chmod a+x ~/bin/repo
export PATH=~/bin:$PATH



# create shared downloads and sstate-cache directory
mkdir -p downloads
mkdir -p sstate-cache

# use a private folder
export XTMP="$$"
mkdir -p "repoclone$XTMP"
cd "repoclone$XTMP"

export REPODIR=`pwd`

if test x"" = x"${RELEASE_VERSION}" -a x"" = x"${RELEASE_BRANCH}" ; then
    #repo init --repo-branch=repo-1 --reference=/opt/AGL/preclone -q -b $TARGETBRANCH -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo
    #GIT_TRACE=1 REPO_TRACE=1 repo init --reference=/opt/AGL/preclone -b $TARGETBRANCH -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo
    repo init --reference=/opt/AGL/preclone -b $TARGETBRANCH -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo
else
  if test x"AGL/meta-renesas-rcar-gen3" = x"${TARGETPROJECT}" ; then
    #repo init --repo-branch=repo-1 --reference=/opt/AGL/preclone -q -b master -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo
    repo init --reference=/opt/AGL/preclone -q -b master -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo
  else
    #repo init --repo-branch=repo-1 --reference=/opt/AGL/preclone -q -b $TARGETBRANCH -m ${RELEASE_BRANCH}_${RELEASE_VERSION}.xml -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo
    repo init --reference=/opt/AGL/preclone -q -b $TARGETBRANCH -m ${RELEASE_BRANCH}_${RELEASE_VERSION}.xml -u https://gerrit.automotivelinux.org/gerrit/AGL/AGL-repo
  fi
fi


# next: repo sync and dump manifest
repo sync --force-broken --force-sync --detach --no-clone-bundle

