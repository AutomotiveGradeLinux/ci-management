# (c) 2017 Kevin Hilman <khilman@baylibre.com>
# License GPLv2

#
# Setup LAVA API authentication tokens for various LAVA labs
#
# Uses user/token pairs from Jenkins secrets
#
# And macthing LAVA lab names for releng-scripts
#
# Strucuture: [JENKINS_LAB_NAME]="LAB_URL;JENKINS_LAB_USER;JENKINS_LAB_TOKEN;RELENG_LAB_NAME"
#

# Let the script handle errors nicely
set +e

declare -A labs
labs=(
      [agl]="https://lava.automotivelinux.org/;$LAB_AGL_USER;$LAB_AGL_TOKEN;lab-agl-core"
#      [baylibre]="http://lava.baylibre.com:10080/;$LAB_BAYLIBRE_USER;$LAB_BAYLIBRE_TOKEN;lab-baylibre-legacy"
)

#
# Ensure python_keyring is set to plaintext.  Required for
# non-interactive use
#
echo "default keyring config"
mkdir -p ~/.local/share/python_keyring/
cat <<EOF >  ~/.local/share/python_keyring/keyringrc.cfg
[backend]
default-keyring=keyring.backends.file.PlaintextKeyring
EOF

set -x
device_available=0
for lab in "${!labs[@]}"; do
    val=${labs[$lab]}
    OFS=${IFS}
    IFS=';'
    arr=(${labs[$lab]})
    IFS=${OFS}

    url=${arr[0]}
    user=${arr[1]}
    token=${arr[2]}
    lava_lab=${arr[3]}
    token_file=$HOME/.local/lab-$lab-token

    if [ -z ${user} ]; then
        echo "WARNING: Lab ${lab}: missing user. Ignoring."
        continue
    fi
    if [ -z ${token} ]; then
        echo "WARNING: Lab ${lab}: missing token. Ignoring."
        continue
    fi

    # LAVA URL with username
    lava_url=${url/:\/\//:\/\/${user}\@}
    full_url=${lava_url}
    full_url+="RPC2/" # entry point for XML-RPC API
    echo "LAVA auth-add for lab: $lab, URL: $full_url"

    # lavacli auth using token
    mkdir -p ~/.config
    lavacli identities add --token ${token} --uri ${url}/RPC2 --username $user $lab

    # lavacli: Find the LAVA lab that has the device available to run the job
    echo -n "lavacli: Checking for $lava_device at $full_url... "
    lavacli_line=$(lavacli -i $lab devices list | grep $lava_device | grep Good | head -1)
    lavacli_line=$(echo "$lavacli_line" | tr -d '[:space:]')

    if [ -z "$lavacli_line" ]; then
        echo "not found."
    fi
    IFS=':'
    arr=($lavacli_line)
    device_status=${arr[1]}
    IFS=${OFS}

    if [ x"$device_status" = x"Idle,Good" ]; then
	echo "lavacli: found a device available: $lavacli_line"
	lavacli_dev=$(echo ${arr[0]} | sed 's/\*\([^(]*\).*/\1/')
	lavacli_tags=$(lavacli -i $lab devices tags list $lavacli_dev | grep \*)
	lavacli_tags=$(echo "$lavacli_tags" | sed 's/\* \(\)/\1/')
	echo "Tags for $lavacli_dev: $lavacli_tags"
    else
	echo "lavacli: did not find any device available: $lavacli_line"
    fi

    # FIXME: encode this better , we might have multiple jobs already queued/running.
    # We have to wait before we 'flood' the queue. Better here than to timeout later!
    retries=1
    if [ x"$device_status" = x"Reserved,Good" ]; then
        retries=30
    elif [ x"$device_status" = x"Running,Good" ]; then
        retries=30
    fi

    # If the device is reserved poll it's status every minutes.
    # The max polling time is set to $retries * 60 seconds = 10 minutes.
    device_available=0
    for i in `seq 1 $retries`
    do
        # device is only available if "idle" or "running"
        # Look if the status of the board has changed from reserved in the lab
        echo -n "Checking for $lava_device at $full_url... "
        lavacli_line=$(lavacli -i $lab devices list | grep $lava_device | grep Good | head -1)
        lavacli_line=$(echo "$lavacli_line" | tr -d '[:space:]')
        if [ -z "$lavacli_line" ]; then
            echo "not found."
            break
        fi
        IFS=':'
        arr=($lavacli_line)
        device_status=${arr[1]}
        IFS=${OFS}

        if [ x"$device_status" = x"Reserved,Good" ]; then
            echo "Device still reserved, retries left: $retries ."
        elif [ x"$device_status" = x"Idle,Good" ]; then
            # IDLE AND GOOD means we can grab it
            device_available=1
            break
        elif [ x"$device_status" = x"Running,Good" ]; then
            echo "Device still running (other job), retries left: $retries ."
        fi
        sleep 60s
    done

    if [ $device_available = 0 ]; then
        echo " Not Available.  Status: $device_status"
        continue
    else
        echo " Found and available.  Status: $device_status"
        export LAVA_LAB=$lava_lab
        break
    fi
done

if [ "$device_available" -eq 0 ]; then
    echo ""
    echo "ERROR: device not found in any available lab."
    exit 0
fi

# Re-enable error detection
set -e
