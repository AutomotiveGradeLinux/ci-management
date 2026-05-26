#!/usr/bin/env bash
# lib/00-ssh.sh – SSH key bootstrap
# Sourced at container start. Installs keys from /run/secrets/* into ~/.ssh
# and starts ssh-agent when multiple identities are needed.
set -euo pipefail

setup_ssh() {
    mkdir -p ~/.ssh
    chmod 700 ~/.ssh

    local added=0
    for var in SSH_GERRIT_KEY_PATH SSH_DOWNLOAD_KEY_PATH SSH_AGLDOCS_KEY_PATH; do
        local path="${!var:-}"
        if [[ -n "$path" && -f "$path" ]]; then
            local dest="$HOME/.ssh/$(basename "$path")"
            cp "$path" "$dest"
            chmod 600 "$dest"
            added=$((added + 1))
        fi
    done

    # Write known_hosts to avoid interactive host-key prompts
    {
        ssh-keyscan -H "${GERRIT_HOST:-gerrit.automotivelinux.org}" 2>/dev/null || true
        ssh-keyscan -H "${ARTIFACT_HOST##*@}" 2>/dev/null || true
        ssh-keyscan -H github.com 2>/dev/null || true
    } >> ~/.ssh/known_hosts 2>/dev/null || true

    if [[ $added -gt 1 ]]; then
        eval "$(ssh-agent -s)"
        for var in SSH_GERRIT_KEY_PATH SSH_DOWNLOAD_KEY_PATH SSH_AGLDOCS_KEY_PATH; do
            local path="${!var:-}"
            if [[ -n "$path" && -f "$path" ]]; then
                ssh-add "$HOME/.ssh/$(basename "$path")" 2>/dev/null || true
            fi
        done
        export SSH_AUTH_SOCK SSH_AGENT_PID
    fi

    # Disable StrictHostKeyChecking as a runtime fallback (keys added above cover the known hosts)
    cat > ~/.ssh/config << 'EOF'
Host *
    StrictHostKeyChecking no
    UserKnownHostsFile ~/.ssh/known_hosts
EOF
    chmod 600 ~/.ssh/config
}
