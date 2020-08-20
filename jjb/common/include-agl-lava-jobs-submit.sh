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
    exit 123
fi
JOB_BASE=$(basename $JOB_FILE .yaml)

# Need to hack the LAVA device-type name in the job file
JOB_FILE_NEW="${JOB_BASE}_${LAVA_LAB}.yaml"
cat $JOB_FILE | sed "s/device_type: $releng_device$/device_type: $lava_device/" > $JOB_FILE_NEW

#
# LAVA job submit, get job ID from lava-tool output
#
JOB_STATUS="${JOB_BASE}_${LAVA_LAB}.status"

if [ -z "$lab" ];then
	echo "WARNING: lab is empty fallback to agl lab"
	lab=agl
fi

job_id=$(lavacli -i $lab jobs submit $JOB_FILE_NEW)
if [ $? -ne 0 ]; then
	echo "ERROR: job submission error"
	exit 123
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

#### echo back to gerrit
eval ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -p 29418 agl-jobbuilder@gerrit.automotivelinux.org gerrit review ${{GERRIT_CHANGE_NUMBER}},${{GERRIT_PATCHSET_NUMBER}} -n NONE --message="Submitted\ to\ LAVA\ as\ job:\ \$JOB_URL" || true


# use lavacli wait job instead of the polling.
lavacli -i $lab jobs wait $job_id --timeout 7200 || true
lavacli -i $lab jobs show $job_id --yaml > $JOB_STATUS
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
	if [ -z "${GERRIT_HOST}" ]; then
		    export GERRIT_HOST="gerrit.automotivelinux.org"
	fi
	SKIPLIST=skiplist
	# detect job type (apps vs non-apps) and get skiplist
	if [ ! -z "$(echo $JOB_NAME | grep 'ci-platform')" ];then
		git clone https://${GERRIT_HOST}/gerrit/src/qa-testdefinitions.git || true
		if [ ! -e qa-testdefinitions ];then
			echo "ERROR: fail to get qa-testdefinitions"
			return 0
		fi
		SKIPDIR=qa-testdefinitions/skiplists/
		SKIPFILE=common
		CK_REPO_NAME="qa-testdefinitions"
	else
		git clone https://${GERRIT_HOST}/gerrit/${GERRIT_PROJECT}.git || true
		# GERRIT_PROJECT could have a / in it
		CK_REPO_NAME="$(basename ${GERRIT_PROJECT})"
		if [ ! -e $CK_REPO_NAME ];then
			echo "ERROR: fail to get $GERRIT_PROJECT"
			return 0
		fi
		SKIPDIR=${CK_REPO_NAME}/
		SKIPFILE=.aglci
	fi
	for skipfile in $SKIPFILE $MACHINE ${GERRIT_PROJECT}
	do
		if [ -e $SKIPDIR/$skipfile ];then
			echo "DEBUG: SKIPLIST: Found $SKIPDIR/$skipfile"
			cat $SKIPDIR/$skipfile >> $SKIPLIST
		fi
	done

	if [ ! -e "$SKIPLIST" ];then
		echo "DEBUG: $SKIPLIST does not exist"
		touch $SKIPLIST
		return 0
	fi

	if [ ! -s "$SKIPLIST" ];then
		echo "DEBUG: $SKIPLIST is empty"
		return 0
	fi
}

handle_result() {
	# example of testline: * lava.lava-test-retry [fail]
	while read testline
	do
		# Check if fail are "normal/accepted"
		TESTNAME=$(echo "$testline" | cut -d' ' -f2)

		# always skip lava.read-feedback (alone)
		if [ x"lava.read-feedback" = x"$TESTNAME" ] ; then
		    continue
		fi

		if [ -z "$(grep $TESTNAME $SKIPLIST)" ];then
			echo "DEBUG: $TESTNAME not in skiplist"
			GOODJOB=0
		else
			echo "DEBUG: $TESTNAME in skiplist"
		fi
	done < job-result.fail
	# clean skiplist
	rm --one-file-system -rf "${CK_REPO_NAME}"
	return 0
}

# Analyze jobs results
lavacli -i $lab results $job_id | tee job-result
set -x
# GOODJOB is equal to 0 if any test fail (and not present in a skiplist), 1 if all test are success
GOODJOB=1
grep '\[fail\]$' job-result > job-result.fail || true

if [ -s job-result.fail ];then
	handle_skiplist
	handle_result
fi

set -x
MSG_FAIL="CI-Image-Boot-Test fail on ${MACHINE}"
MSG_SUCCESS="CI-Image-Boot-Test success on ${MACHINE}"
MSG_BUILD_LOG="${BUILD_URL}consoleFull"
MSG_JOBFAIL="Failed jobs:
$(cat job-result.fail)"

if [ $GOODJOB -eq 0 ];then
        #construct message
cat << EOF > .msg
$MSG_FAIL

Build log available at: $MSG_BUILD_LOG

$MSG_JOBFAIL
EOF
        # escape
        sed -i -e "s/ /\\\ /g" .msg
	# send -1
	eval ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -p 29418 agl-jobbuilder@gerrit.automotivelinux.org gerrit review ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER} --verified +1 --label ci-image-boot-test=-1 -n NONE --message='"$(cat .msg)"' || true
else
        #construct message
cat << EOF > .msg
$MSG_SUCCESS

Build log available at: $MSG_BUILD_LOG
EOF
        # escape
        sed -i -e "s/ /\\\ /g" .msg
	# send +1
	eval ssh -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" -p 29418 agl-jobbuilder@gerrit.automotivelinux.org gerrit review ${GERRIT_CHANGE_NUMBER},${GERRIT_PATCHSET_NUMBER} --verified +1 --label ci-image-boot-test=+1 -n NONE --message='"$(cat .msg)"' || true
fi
set +x

# after one successful submit, we're done
if [ x"$status" = x"Complete" ]; then
    exit 0
fi
#exit 123
# for now do not fail
exit 0
