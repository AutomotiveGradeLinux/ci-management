
echo '# CI: Enabling ptest in image ... ' >> conf/local.conf
echo 'DISTRO_FEATURES_append = " ptest"' >> conf/local.conf
echo 'EXTRA_IMAGE_FEATURES_append = " ptest-pkgs"' >> conf/local.conf


