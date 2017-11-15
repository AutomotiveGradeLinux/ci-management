# (c) 2017 Kevin Hilman <khilman@baylibre.com>
# License GPLv2
#
# Submit LAVA YAML job file (default testjob.yaml) to first available LAVA lab
# with matching device-type
#
JOB_FILE=${1:-testjob.yaml}

if [ ! -e $JOB_FILE ]; then
    echo "ERROR: LAVA job file $JOB_FILE not present."
    exit 1
fi
JOB_BASE=$(basename $JOB_FILE .yaml)

# Need to hack the LAVA device-type name in the job file
JOB_FILE_NEW="${JOB_BASE}_${LAVA_LAB}.yaml"
cat $JOB_FILE | sed "s/device_type: $releng_device/device_type: $lava_device/" > $JOB_FILE_NEW

#
# LAVA job submit, get job ID from lava-tool output
#
JOB_STATUS="${JOB_BASE}_${LAVA_LAB}.status"
lava-tool submit-job $full_url $JOB_FILE_NEW |tee $JOB_STATUS
# Printing the job URL in the log
grep "submitted as job:" $JOB_STATUS
job_id=$(grep "submitted as job:" $JOB_STATUS | sed 's/.*\/\([0-9]*$\)/\1/')

#
# LAVA wait job events, wait for job to finish
#
lava-tool wait-job-events --job-id $job_id $full_url

#
# LAVA job details, get job status from lava-tool output
#
lava-tool job-details $full_url $job_id | tee $JOB_STATUS

IFS=':'
line=$(grep "^status:" $JOB_STATUS | tr -d '[:space:]')
arr=($line)
status=${arr[1]}
IFS=${OFS}

echo "LAVA job $job_id completed with status: $status"

echo "####"
echo "#### Start: Output from LAVA job $job_id ####"
echo "####"

JOB_OUTPUT="${JOB_BASE}_output.yaml"
JOB_LOG="${JOB_BASE}_output.log"
curl -s -o $JOB_OUTPUT $full_url/scheduler/job/$job_id/log_file/plain
cat $JOB_OUTPUT | grep '"target",' | sed -e 's#- {"dt".*"lvl".*"msg":."##g' -e 's#"}$##g' | tee $JOB_LOG

echo "####"
echo "#### End: Output from LAVA job $job_id ####"
echo "####"

# after one successful submit, we're done
if [ x"$status" = x"Complete" ]; then
    exit 0
fi

exit 1
