#!/bin/bash

# Do not execute on master branch (new appfw)
if test x"master" = x"${GERRIT_BRANCH}" ; then
exit 0
fi
