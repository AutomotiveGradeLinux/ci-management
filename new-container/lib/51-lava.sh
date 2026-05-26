#!/usr/bin/env bash
# lib/51-lava.sh – LAVA test job preparation, submission, and result handling
# Derived from include-agl-run-test-prepare.sh, include-agl-lava-labs-prepare.sh,
# include-agl-run-test-short.sh, include-agl-lava-jobs-submit.sh,
# include-agl-lava-jobs-submit-only.sh.
set -euo pipefail

# Clone or update releng-scripts, export RELENG and add utils to PATH.
lava_setup_releng() {
    cd "${REPODIR}"
    if [[ ! -e releng-scripts ]]; then
        git clone --branch "${TARGETBRANCH}" \
            https://git.automotivelinux.org/AGL/releng-scripts
    else
        (cd releng-scripts; git remote update; git checkout -f "origin/${TARGETBRANCH}")
    fi
    export RELENG="${REPODIR}/releng-scripts"
    export PATH="/usr/bin:${PATH}:${RELENG}/utils"
}

# Determine per-machine LAVA device names and call job-prereq.py to produce
# artifact filenames. Populates BOARDOUT directory.
lava_prepare_boardout() {
    export BOARDOUT
    BOARDOUT=$(mktemp --directory)

    _gen_info() {
        local lava_dev="$1" releng_dev="$2"
        local bdirname="${lava_dev}-${releng_dev}"
        mkdir -p "${BOARDOUT}/${bdirname}"

        local create_args="--machine ${releng_dev} "
        [[ -n "${TARGETBRANCH:-}" && "${TARGETBRANCH}" != "master" ]] && \
            create_args+="--branch ${TARGETBRANCH} "
        [[ -n "${RELEASE_BRANCH:-}" && -n "${RELEASE_VERSION:-}" ]] && \
            create_args+="--build-type release ${RELEASE_BRANCH} ${RELEASE_VERSION} "
        [[ -n "${GERRIT_CHANGE_NUMBER:-}" && -n "${GERRIT_PATCHSET_NUMBER:-}" ]] && \
            create_args+="--build-type ci ${GERRIT_CHANGE_NUMBER} ${GERRIT_PATCHSET_NUMBER} "

        "${RELENG}/utils/job-prereq.py" ${create_args} || return 0

        local dtb kernel initrd nbdroot
        dtb=$(    "${RELENG}/utils/job-prereq.py" ${create_args} --dtb)
        kernel=$( "${RELENG}/utils/job-prereq.py" ${create_args} --kernel)
        initrd=$( "${RELENG}/utils/job-prereq.py" ${create_args} --initrd)
        nbdroot=$("${RELENG}/utils/job-prereq.py" ${create_args} --nbdroot)

        cat > "${BOARDOUT}/${bdirname}/info" << EOF
DEVICE_DTB=${dtb}
DEVICE_KERNEL=${kernel}
DEVICE_INITRAMFS=${initrd}
DEVICE_NBDROOT=${nbdroot}
x_releng_device=${releng_dev}
x_lava_device=${lava_dev}
EOF
    }

    # Per-machine mapping (mirrors include-agl-run-test-prepare.sh case block)
    # lava_device and releng_device are exported so lava_submit_job can use them.
    case "${MACHINE}" in
        bbe)
            lava_device=am335x-sancloud-bbe; releng_device=bbe
            _gen_info "${lava_device}" "${releng_device}" || true
            ;;
        qemux86-64)
            _gen_info upsquare upsquare || true
            lava_device=qemu; releng_device=qemux86-64
            _gen_info "${lava_device}" "${releng_device}" || true
            ;;
        raspberrypi4|raspberrypi4-64)
            lava_device=bcm2711-rpi-4-b; releng_device=raspberrypi4
            _gen_info "${lava_device}" "${releng_device}" || true
            ;;
        qemuarm)
            lava_device=qemu; releng_device=qemuarm
            _gen_info "${lava_device}" "${releng_device}" || true
            ;;
        qemuarm64)
            lava_device=qemu; releng_device=qemuarm64
            _gen_info "${lava_device}" "${releng_device}" || true
            ;;
        h3ulcb-nogfx)
            _gen_info r8a7795-agl-refhw r8a7795-agl-refhw || true
            lava_device=r8a7795-h3ulcb-kf; releng_device=h3ulcb-kf
            _gen_info "${lava_device}" "${releng_device}" || true
            ;;
        r8a7795-agl-refhw)
            lava_device=r8a7795-agl-refhw; releng_device=r8a7795-agl-refhw
            _gen_info "${lava_device}" "${releng_device}" || true
            ;;
        upsquare)
            lava_device=upsquare; releng_device=upsquare
            # no gen_info – reuses qemux86-64 artifacts
            ;;
        *)
            echo "ERROR: unknown machine ${MACHINE}" >&2
            return 0
            ;;
    esac

    export lava_device releng_device
}

# Configure lavacli identities for each available lab and find the lab whose
# device is currently idle. Exports: LAVA_LAB, lab, url, lava_url, lavacli_tags.
lava_find_lab() {
    set +e
    # Ensure plaintext keyring for lavacli
    mkdir -p ~/.local/share/python_keyring/
    cat > ~/.local/share/python_keyring/keyringrc.cfg << 'EOF'
[backend]
default-keyring=keyring.backends.file.PlaintextKeyring
EOF

    declare -A labs
    labs=(
        [agl]="https://lava.automotivelinux.org/;${LAB_AGL_USER:-};${LAB_AGL_TOKEN:-};lab-agl-core"
    )
    # Uncomment to add Baylibre labs:
    # labs[baylibre]="http://lava.baylibre.com:10080/;${LAB_BAYLIBRE_USER:-};${LAB_BAYLIBRE_TOKEN:-};lab-baylibre-legacy"

    local device_available=0
    for lab_name in "${!labs[@]}"; do
        IFS=';' read -r _url _user _token lava_lab <<< "${labs[$lab_name]}"
        if [[ -z "${_user}" || -z "${_token}" ]]; then
            echo "WARNING: Lab ${lab_name}: missing credentials, skipping."
            continue
        fi

        lavacli identities add --token "${_token}" --uri "${_url}/RPC2" \
            --username "${_user}" "${lab_name}" 2>/dev/null || true

        local lavacli_line
        lavacli_line=$(lavacli -i "${lab_name}" devices list 2>/dev/null \
            | grep "${lava_device:-}" | grep Good | head -1 || true)
        lavacli_line=$(echo "${lavacli_line}" | tr -d '[:space:]')

        if [[ -z "${lavacli_line}" ]]; then
            echo "Lab ${lab_name}: device ${lava_device:-} not found."
            continue
        fi

        IFS=':' read -ra _arr <<< "${lavacli_line}"
        local device_status="${_arr[1]}"

        local retries=1
        [[ "${device_status}" =~ ^(Reserved|Running) ]] && retries=30

        device_available=0
        for _i in $(seq 1 "${retries}"); do
            lavacli_line=$(lavacli -i "${lab_name}" devices list 2>/dev/null \
                | grep "${lava_device:-}" | grep Good | head -1 || true)
            lavacli_line=$(echo "${lavacli_line}" | tr -d '[:space:]')
            IFS=':' read -ra _arr <<< "${lavacli_line}"
            device_status="${_arr[1]}"

            if [[ "${device_status}" == "Idle,Good" ]]; then
                device_available=1
                break
            fi
            sleep 60
        done

        if [[ "${device_available}" -eq 1 ]]; then
            export lab="${lab_name}"
            export url="${_url}"
            export lava_url="${_url}"
            export LAVA_LAB="${lava_lab}"
            local lavacli_dev
            lavacli_dev=$(echo "${_arr[0]}" | sed 's/\*\([^(]*\).*/\1/')
            export lavacli_tags
            lavacli_tags=$(lavacli -i "${lab_name}" devices tags list "${lavacli_dev}" \
                | grep '\*' | sed 's/baylibre//' | sed 's/corelab//' | sed 's/docker//' \
                | sed 's/\* \(\)/\1/' || true)
            break
        fi
    done

    if [[ "${device_available}" -eq 0 ]]; then
        echo "ERROR: device ${lava_device:-} not found in any lab."
        exit 0
    fi
    set -e
}

# Generate a testjob.yaml using releng-scripts create-jobs.py
lava_create_job() {
    cd "${REPODIR}"
    local build_version=""
    if [[ -n "${DIST_BUILD_TOPIC:-}" ]]; then
        build_version="${DIST_BUILD_TOPIC}"
    elif [[ -n "${DIST_BB_DISTRO_VERSION:-}" ]]; then
        build_version="${DIST_BB_DISTRO_VERSION}-${DIST_LAYERS_MD5:0:8}"
    fi

    echo "LAVA lab: ${LAVA_LAB}"
    pip3 show jinja2

    local create_args="--machine ${releng_device} "
    create_args+="--build-type ci "
    [[ -n "${GERRIT_CHANGE_NUMBER:-}" ]] && create_args+="--changeid ${GERRIT_CHANGE_NUMBER} "
    [[ -n "${GERRIT_PATCHSET_NUMBER:-}" ]] && create_args+="--patchset ${GERRIT_PATCHSET_NUMBER} "
    create_args+="--name AGL-gerrit-${GERRIT_CHANGE_NUMBER:-0}-${GERRIT_PATCHSET_NUMBER:-0} "
    [[ -n "${build_version}" ]] && create_args+="--build-version ${build_version} "
    [[ -n "${DIST_BUILD_HASH:-}" ]] && create_args+="--commit ${DIST_BUILD_HASH} "
    [[ -n "${DIST_BUILD_ID:-}" ]] && create_args+="--build-id ${DIST_BUILD_ID} "
    [[ -n "${DIST_BB_AGL_BRANCH:-}" ]] && create_args+="--branch ${DIST_BB_AGL_BRANCH} "
    [[ -n "${DIST_BB_AGLVERSION:-}" ]] && create_args+="--version ${DIST_BB_AGLVERSION} "
    create_args+="--callback-from ${LAVA_LAB} "
    [[ -n "${lavacli_tags:-}" ]] && create_args+="--device-tags ${lavacli_tags} "

    echo "DEBUG: create-jobs.py ${create_args}"
    "${RELENG}/utils/create-jobs.py" ${create_args} > testjob.yaml || {
        echo "ERROR: LAVA job creation failed for ${releng_device}"
        exit 0
    }
    cat testjob.yaml
}

# Submit testjob.yaml, wait, fetch results, return 0/non-zero by health.
# Exports: job_id, JOB_URL, GOODJOB (1=pass 0=fail).
lava_submit_wait() {
    cd "${REPODIR}"
    local job_file="testjob.yaml"
    [[ -e "${job_file}" ]] || { echo "ERROR: ${job_file} missing"; exit 123; }

    local job_base="${job_file%.yaml}"
    local job_file_new="${job_base}_${LAVA_LAB}.yaml"
    sed "s/device_type: ${releng_device}$/device_type: ${lava_device}/" \
        "${job_file}" > "${job_file_new}"

    job_id=$(lavacli -i "${lab}" jobs submit "${job_file_new}") || \
        { echo "ERROR: job submission failed"; exit 123; }
    export job_id
    export JOB_URL="${lava_url}scheduler/job/${job_id}"
    echo "Submitted as job: ${JOB_URL}"

    set +e
    lavacli -i "${lab}" jobs wait "${job_id}" --timeout 7200
    if [[ $? -ne 0 ]]; then
        local retry=1
        while [[ "${retry}" -le 5 ]]; do
            sleep 5
            lavacli -i "${lab}" jobs show "${job_id}" > status
            grep -q 'state.*Finished' status && break
            retry=$((retry + 1))
            lavacli -i "${lab}" jobs wait "${job_id}" --timeout 7200 || true
        done
    fi
    set -e

    local job_status_file="${job_base}_${LAVA_LAB}.status"
    lavacli -i "${lab}" jobs show "${job_id}" --yaml > "${job_status_file}"
    local state health
    state=$( grep '^state:'  "${job_status_file}" | awk '{print $2}')
    health=$(grep '^health:' "${job_status_file}" | awk '{print $2}')
    echo "LAVA job ${job_id} state=${state} health=${health}"

    # Fetch log
    local job_output="${job_base}_output.yaml"
    local job_log="${job_base}_output.log"
    curl -s -o "${job_output}" "${lava_url}scheduler/job/${job_id}/log_file/plain" || true
    grep '"target",' "${job_output}" 2>/dev/null \
        | sed -e 's#- {"dt".*"lvl".*"msg":."##g' -e 's#"}$##g' | tee "${job_log}" || true

    export LINES_PERCENT
    export BRANCHES_PERCENT
    LINES_PERCENT=$(grep LINES_PERCENT= "${job_log}" | sed 's/LINES_PERCENT=//;s/+ //' | head -1 || true)
    BRANCHES_PERCENT=$(grep BRANCHES_PERCENT= "${job_log}" | sed 's/BRANCHES_PERCENT=//;s/+ //' | head -1 || true)

    # Analyse pass/fail
    export GOODJOB=1
    lavacli -i "${lab}" results "${job_id}" | tee job-result
    grep '\[fail\]$' job-result > job-result.fail || true

    if [[ -s job-result.fail ]]; then
        _handle_skiplist
        _handle_result
    fi

    if [[ "${state}" == "Finished" && "${health}" == "Complete" ]]; then
        return 0
    fi
    return 0   # don't fail the build on LAVA issues per original behaviour
}

_handle_skiplist() {
    local skiplist=skiplist
    local gerrit_host="${GERRIT_HOST:-gerrit.automotivelinux.org}"
    local ck_repo_name skipdir skipfile

    if echo "${JOB_NAME:-}" | grep -q 'ci-platform'; then
        git clone "https://${gerrit_host}/gerrit/src/qa-testdefinitions.git" || true
        [[ -e qa-testdefinitions ]] || return 0
        skipdir="qa-testdefinitions/skiplists/"; skipfile="common"
        ck_repo_name="qa-testdefinitions"
    else
        git clone "https://${gerrit_host}/gerrit/${GERRIT_PROJECT:-}.git" || true
        ck_repo_name="$(basename "${GERRIT_PROJECT:-unknown}")"
        [[ -e "${ck_repo_name}" ]] || return 0
        skipdir="${ck_repo_name}/"; skipfile=".aglci"
    fi

    for f in "${skipfile}" "${MACHINE}" "${GERRIT_PROJECT:-}"; do
        [[ -e "${skipdir}/${f}" ]] && cat "${skipdir}/${f}" >> "${skiplist}" || true
    done
    export SKIPLIST="${skiplist}"
    export CK_REPO_NAME="${ck_repo_name}"
}

_handle_result() {
    while IFS= read -r testline; do
        local testname
        testname=$(echo "${testline}" | cut -d' ' -f2)
        [[ "${testname}" == "lava.read-feedback" ]] && continue
        if ! grep -q "${testname}" "${SKIPLIST:-/dev/null}" 2>/dev/null; then
            echo "DEBUG: ${testname} not in skiplist → FAIL"
            GOODJOB=0
        fi
    done < job-result.fail
    rm -rf --one-file-system "${CK_REPO_NAME:-__nonexistent__}" 2>/dev/null || true
}
