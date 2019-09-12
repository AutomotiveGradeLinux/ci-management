# (c) 2019 Khouloud Touil <ktouil@baylibre.com>
# License GPLv2
#
################################################################################
## Send email reports after the job is done.
################################################################################

set -x

UPLOAD_URL_BASE=http://download.automotivelinux.org/AGL/upload/ci
UPLOAD_URL=${UPLOAD_URL_BASE}/${GERRIT_CHANGE_NUMBER}/${GERRIT_PATCHSET_NUMBER}/qemux86-64/

set | grep MACH

send_email_report()
{
wget -q ${UPLOAD_URL}/build-info || echo "ERROR: send_email_report: failed to get build-info"

if [ ! -s build-info ]; then
	return 0
fi
	cat build-info
	source build-info

if [ -n "$KCI_EMAIL_AUTH_TOKEN" ]; then
	KCI_API='http://kernelci.dev.baylibre.com:8081'
	TREE_NAME='AGL-yocto'
	BRANCH=$DIST_BB_AGL_BRANCH
	if [[ ! -z $DIST_BUILD_TOPIC ]]; then
	    GIT_DESCRIBE=$DIST_BUILD_TOPIC
	else
	    GIT_DESCRIBE=$DIST_BB_DISTRO_VERSION-${DIST_LAYERS_MD5:0:8}
	fi
	PLAN='agl-testplan'
	curl -X POST -H "Authorization: $KCI_EMAIL_AUTH_TOKEN" -H "Content-Type: application/json" -d '{"job": "'$TREE_NAME'", "kernel": "'$GIT_DESCRIBE'", "git_branch": "'$BRANCH'", "report_type": "test", "plan": "'$PLAN'", "send_to": ["automotive-testreports@lists.linuxfoundation.org"], "format": ["txt"], "delay": 3600}' ${KCI_API}/send || echo "ERROR: send_email_report: curl"
	echo "The test email reportS will be sent with a delay of 1 hour "
fi
}

send_email_report
