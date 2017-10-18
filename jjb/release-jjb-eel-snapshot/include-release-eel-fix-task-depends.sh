
# HOTFIX for yocto bug https://bugzilla.yoctoproject.org/show_bug.cgi?id=12070
echo "" >> conf/local.conf
echo 'do_image_complete[deptask] += "do_populate_lic"' >> conf/local.conf
