# (c) 2017 Jan-Simon Moeller dl9pf(at)gmx.de
# License GPLv2

################################################################################
## Add archiver
################################################################################

# only morty and newer support the cve-check, so check for master branch

echo '' >> conf/auto.conf
echo 'INHERIT += "cve-check"' >> conf/auto.conf
