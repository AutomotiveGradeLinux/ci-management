# (c) 2021 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

################################################################################
## auto.conf remove wic for simple CI builds
################################################################################
cat << EOF >> conf/auto.conf

# remove wic as CI does only use ext4 in lava
# this saves i/o and time
IMAGE_FSTYPES:remove = "wic.xz"
IMAGE_FSTYPES:remove = "wic.bmap"
IMAGE_FSTYPES:remove = "wic.vmdk.xz"



EOF