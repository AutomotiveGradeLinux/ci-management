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
declare -A labs
labs=(
      [agl]="https://lava.automotivelinux.org/;$LAB_AGL_USER;$LAB_AGL_TOKEN;lab-agl-core"
      [baylibre]="http://lava.baylibre.com:10080/;$LAB_BAYLIBRE_USER;$LAB_BAYLIBRE_TOKEN;lab-baylibre-legacy"
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

declare -A agl_lava_releng_aliases
agl_lava_releng_aliases=(
    [raspberrypi3]="raspberrypi3-uboot;raspberrypi3"
    [qemux86-64]="qemu;qemux86-64"
    [m3ulcb-nogfx]="r8a7796-m3ulcb;m3ulcb"
    [porter-nogfx]="renesas-porter;renesas-porter"
    [dra7xx-evm]="ti-vayu-uboot;ti-vayu-uboot"
)

OFS=${IFS}
IFS=';'
arr=(${agl_lava_releng_aliases[$MACHINE]})
IFS=${OFS}
lava_device=${arr[0]}
releng_device=${arr[1]}
# And agl_device=${MACHINE}

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
    full_url=${url/:\/\//:\/\/${user}\@}
    full_url+="RPC2/" # entry point for XML-RPC API
    echo "LAVA auth-add for lab: $lab, URL: $full_url"

    # LAVA auth using token
    echo ${token} > $token_file
    lava-tool auth-add --token $token_file $full_url
    if [ $? != 0 ]; then
        echo "ERROR: Lab ${lab}: lava-tool auth-add failed."
        continue
    fi
    rm -f $token_file

    # Find the LAVA Lab that has the device available to run the job
    echo -n "Checking for $lava_device at $full_url... "
    line=$(lava-tool devices-list $full_url |grep $lava_device | tr -d '[:space:]')
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
        export LAVA_LAB=$lava_lab
        break
    fi
done

if [ "$device_available" -eq 0 ]; then
    echo ""
    echo "ERROR: device not found in any available lab."
    exit 0
fi
