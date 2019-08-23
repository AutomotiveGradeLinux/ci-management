# (c) 2017 Kevin Hilman <khilman@baylibre.com>
# License GPLv2
#
# Submit LAVA YAML job file (default testjob.yaml) to first available LAVA lab
# with matching device-type
#
#JOB_FILE=${1:-testjob.yaml}
JOB_FILE=testjob.yaml

if [ ! -e $JOB_FILE ]; then
    JOB_FILE=$1
fi

if [ ! -e $JOB_FILE ]; then
    echo "ERROR: LAVA job file $JOB_FILE not present."
    exit 1
fi
JOB_BASE=$(basename $JOB_FILE .yaml)

# Need to hack the LAVA device-type name in the job file
JOB_FILE_NEW="${JOB_BASE}_${LAVA_LAB}.yaml"
cat $JOB_FILE | sed "s/device_type: $releng_device$/device_type: $lava_device/" > $JOB_FILE_NEW

#
# LAVA job submit, get job ID from lava-tool output
#
JOB_STATUS="${JOB_BASE}_${LAVA_LAB}.status"

job_id=$(lavacli -i $lab jobs submit $JOB_FILE_NEW)
if [ $? -ne 0 ]; then
	echo "ERROR: job submission error"
	exit 1
fi
# Printing the job URL in the log
echo "THe job id is: ${job_id}"
JOB_URL="${url}scheduler/job/${job_id}"

echo ""
echo ""
echo "Submitted as job: $JOB_URL"
echo ""
echo "####################################################"
echo ""

# use lavacli wait job instead of the polling.
lavacli -i agl jobs wait $job_id --timeout 7200
lavacli -i agl jobs show $job_id --yaml > $JOB_STATUS
state=$(grep ^state: $JOB_STATUS| cut -d' ' -f2)
if [ "$state" == "Finished" ]; then
        status=$(grep ^health: $JOB_STATUS| cut -d' ' -f2)
        echo "LAVA job $job_id completed with status: $status"
fi

echo "####"
echo "#### Start: Output from LAVA job $job_id ####"
echo "####"

JOB_OUTPUT="${JOB_BASE}_output.yaml"
JOB_LOG="${JOB_BASE}_output.log"
curl -s -o $JOB_OUTPUT $lava_url/scheduler/job/$job_id/log_file/plain
cat $JOB_OUTPUT | grep '"target",' | sed -e 's#- {"dt".*"lvl".*"msg":."##g' -e 's#"}$##g' | tee $JOB_LOG
cat $JOB_OUTPUT | grep '"error_msg":' | sed -e 's#.*"error_msg": "##g' -e 's#", ".*##g' | tee -a $JOB_LOG

echo "####"
echo "#### End: Output from LAVA job $job_id ####"
echo "####"

handle_skiplist() {
	# detect job type (apps vs non-apps) and get skiplist
	echo $JOB_NAME | grep -q 'ci-platform'
	if [ $? -eq 0 ];then
		git clone https://${GERRIT_HOST}/gerrit/src/qa-testdefinitions.git
		if [ $? -ne ];then
			echo "ERROR: fail to get qa-testdefinitions"
			return 1
		fi
		SKIPLIST=qa-testdefinitions/skiplists/common
		CK_REPO_NAME="qa-testdefinitions"
	else
		git clone https://${GERRIT_HOST}/gerrit/${GERRIT_PROJECT}.git
		if [ $? -ne ];then
			echo "ERROR: fail to get $GERRIT_PROJECT"
			return 1
		fi
		SKIPLIST=${GERRIT_PROJECT}/.aglci
		CK_REPO_NAME="${GERRIT_PROJECT}"
	fi

	if [ -e "$SKIPLIST" ];then
		echo "DEBUG: $SKIPLIST does not exists"
		return 0
	fi

	if [ ! -s "$SKIPLIST" ];then
		echo "DEBUG: $SKIPLIST is empty"
		return 0
	fi

	# example of testline: * lava.lava-test-retry [fail]
	while read testline
	do
		# Check if fail are "normal/accepted"
		TESTNAME=$(echo $testline | cut -d' ' -f2)
		grep -q $TESTNAME $SKIPLIST
		if [ $? -ne 0 ];then
			echo "DEBUG: $TESNAME not in skiplist"
			GOODJOB=0
		else
			echo "DEBUG: $TESNAME in skiplist"
		fi
	done < job-result.fail
	# clean skiplist
	rm --one-file-system -rf "${CK_REPO_NAME}"
	return 0
}

# Analyze jobs results
lavacli results $job_id | tee job-result
# GOODJOB is equal to 0 if any test fail (and not present in a skiplist), 1 if all test are success
GOODJOB=1
grep -v '^\* ' | grep '\[fail\]$' > job-result.fail
if [ -s job-result.fail ];then
	handle_skiplist
fi

if [ $GOODJOB -eq 0 ];then
	# send -1
	ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -p 29418 agl-jobbuilder@gerrit.automotivelinux.org gerrit review ${{GERRIT_CHANGE_NUMBER}},${{GERRIT_PATCHSET_NUMBER}} --verified +1 --label ci-image-boot-test=-1 -n NONE --message='CI-Image-Boot-Test\ fail' || true
else
	# send +1
	ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -p 29418 agl-jobbuilder@gerrit.automotivelinux.org gerrit review ${{GERRIT_CHANGE_NUMBER}},${{GERRIT_PATCHSET_NUMBER}} --verified +1 --label ci-image-boot-test=+1 -n NONE --message='CI-Image-Boot-Test\ success' || true
fi

# after one successful submit, we're done
if [ x"$status" = x"Complete" ]; then
    exit 0
fi

#exit 1
# for now do not fail
exit 0
