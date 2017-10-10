# (c) 2017 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

echo "ENFORCE RPI3 to use uImage (for CI)"
echo 'KERNEL_IMAGETYPE_raspberrypi3 := "uImage"' >> conf/local.conf