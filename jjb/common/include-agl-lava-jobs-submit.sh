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

# after one successful submit, we're done
if [ x"$status" = x"Complete" ]; then
    exit 0
fi

#exit 1
# for now do not fail
exit 0
