echo "########## Job cost (estimate) ############"

set +e
#set -x
# Retrieve the current uptime (in seconds)
uptime=$(awk '{print $1}' /proc/uptime)
# Convert to integer by truncating fractional part' and round up by one
((uptime=${uptime%\.*}+1))
instance_type=$(curl -s http://169.254.169.254/latest/meta-data/instance-type | sed -e "s#-iops##g")
#echo "INFO: Retrieving Pricing Info for: $instance_type"
url="https://pricing.vexxhost.net/v1/pricing/$instance_type/cost?seconds=$uptime"
#echo "url=$url"
json_block=$(curl -s "$url")
echo "$json_block"

set -e
echo "########## Job cost (estimate) ############"
