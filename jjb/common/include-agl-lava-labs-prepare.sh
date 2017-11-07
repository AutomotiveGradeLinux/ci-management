# (c) 2017 Kevin Hilman <khilman@baylibre.com>
# License GPLv2

#
# Setup LAVA API authentication tokens for various LAVA labs
#
# Uses user/token pairs from Jenkins secrets
#
declare -A labs
labs=(
    [agl]="https://lava.automotivelinux.org/;$LAB_AGL_USER;$LAB_AGL_TOKEN"
    [baylibre]="http://lava.baylibre.com:10080/;$LAB_BAYLIBRE_USER;$LAB_BAYLIBRE_TOKEN"
#    [baylibre_seattle]="http://lava.ished.com/;$LAB_BAYLIBRE_SEATTLE_USER;$LAB_BAYLIBRE_SEATTLE_TOKEN"
    )

echo "## ${MACHINE} ##"
__MACHINE=${MACHINE%-nogfx}

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

for lab in "${!labs[@]}"; do
    val=${labs[$lab]}
    OFS=${IFS}
    IFS=';'
    arr=(${labs[$lab]})
    IFS=${OFS}

    url=${arr[0]}
    user=${arr[1]}
    token=${arr[2]}
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
    full_url=${url/:\/\//:\/\/${user}\@}
    echo "LAVA auth-add for lab: $lab, URL: $full_url"

    # LAVA auth using token
    echo ${token} > $token_file
    lava-tool auth-add --token $token_file $full_url
    if [ $? != 0 ]; then
	echo "ERROR: Lab ${lab}: lava-tool auth-add failed."
    fi
    rm -f $token_file

    # Find the LAVA Lab that has the device available to run the job
    echo -n "Checking for $__MACHINE at $full_url... "
    line=$(lava-tool devices-list $full_url |grep $__MACHINE | tr -d '[:space:]')
    if [ -z "$line" ]; then
    echo "not found."
    continue
    fi
    IFS='|'
    arr=($line)
    device_status=${arr[2]}
    IFS=${OFS}

    # device is only available if "idle" or "running"
    device_available=0
    if [ x"$device_status" = x"idle" ]; then
    device_available=1
    elif [ x"$device_status" = x"running" ]; then
    device_available=1;
    fi

    if [ $device_available = 0 ]; then
    echo " Not Available.  Status: $device_status"
    continue
    else
    echo " Found and available.  Status: $device_status"
    export LAVA_LAB=$lab
    fi
done
