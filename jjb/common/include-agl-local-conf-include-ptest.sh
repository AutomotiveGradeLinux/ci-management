
echo '# CI: Enabling ptest in image ... ' >> conf/local.conf
echo 'DISTRO_FEATURES:append = " ptest"' >> conf/local.conf
echo 'EXTRA_IMAGE_FEATURES:append = " ptest-pkgs"' >> conf/local.conf


