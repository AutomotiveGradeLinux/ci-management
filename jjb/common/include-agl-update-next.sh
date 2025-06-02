#!/bin/bash

# safety net
if test x"master" = x"${TARGETBRANCH}" ; then
    pushd $MYPROJECT
     git config --local --add gitreview.username agl-jobbuilder
     git config --local --add user.email collab-it+agl-jobbuilder@linuxfoundation.org
     pip3 install git-review
     export PATH=/home/jenkins/.local/bin:$PATH
     git review -s
     git remote -v update
     git checkout -b next gerrit/next
     git rebase gerrit/master
     git push -f gerrit HEAD:next -f
    popd
fi

cd ..
