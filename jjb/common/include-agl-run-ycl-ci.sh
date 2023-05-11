# (c) 2023 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

################################################################################
## Run yocto-check-layer over AGL layers
################################################################################

pushd

# meta-agl
pushd meta-agl
  if test -x scripts/ci-yocto-check-layer.sh ; then
    ./scripts/ci-yocto-check-layer.sh
  fi
popd


# meta-agl-demo
pushd meta-agl-demo
  if test -x scripts/ci-yocto-check-layer.sh ; then
    ./scripts/ci-yocto-check-layer.sh
  fi
popd


# meta-agl-devel
#pushd meta-agl-devel
#  for i in `find . -name "run-yocto-check-layer.sh" | sed -e "s#/scripts/run-yocto-check-layer.sh##g" | sort | uniq` ; do
#    pushd $i
#      if test -x ./scripts/run-yocto-check-layer.sh ; then
#        ./scripts/run-yocto-check-layer.sh
#      fi
#    popd
#  done
#popd
