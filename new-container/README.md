# new-container – AGL CI Container Scripts

Self-contained replacement for the Jenkins Job Builder (JJB) pipeline in `jjb/`.

Every job that previously required Jenkins, its JJB YAML, and a concatenation
of `include-*.sh` snippets is now a **standalone shell script** that can be run
inside a Docker container with nothing else installed.

## Structure

```
new-container/
├── Dockerfile            – AGL build container (Ubuntu 22.04 + Yocto host deps)
├── secrets.env.example   – All required env vars / secret paths, documented
├── lib/                  – Reusable function library (sourced, never exec'd)
│   ├── 00-ssh.sh         – SSH key installation + ssh-agent bootstrap
│   ├── 00-env.sh         – GERRIT/MACHINE/TARGET* normalisation + CI-var mapping
│   ├── 10-repo.sh        – repo init / sync
│   ├── 20-select.sh      – repo download / gerrit change selection
│   ├── 30-aglsetup.sh    – install-buildtools + aglsetup.sh + sstate/downloads
│   ├── 31-localconf.sh   – local.conf / auto.conf fragment writers
│   ├── 40-bitbake.sh     – bitbake_image / bitbake_sdk / bitbake_ycl
│   ├── 50-publish.sh     – rsync artifact publishing helpers
│   ├── 51-lava.sh        – LAVA job prep, submission, result handling
│   ├── 52-email-kci.sh   – KernelCI email report + build-meta publishing
│   ├── 60-apps.sh        – AGL app build helpers
│   ├── 70-container.sh   – docker-worker-generator build/export
│   ├── 80-prefetch.sh    – weekly download-mirror pre-fetch
│   ├── 81-docs.sh        – AGL docs build + GitHub Pages publish
│   └── 90-gerrit-review.sh – Gerrit vote via SSH (no-op if GERRIT_REVIEW_HOST unset)
└── jobs/                 – Thin entrypoint scripts (one per job type)
    ├── verify-cib.sh           – Gerrit verify build (CIB) per machine
    ├── verify-cibt.sh          – Gerrit verify LAVA boot test (CIBT)
    ├── verify-ycl.sh           – yocto-check-layer CI
    ├── verify-refhw-cib.sh     – refhw CIB (delegates to verify-cib.sh)
    ├── verify-refhw-cibt.sh    – refhw CIBT (delegates to verify-cibt.sh)
    ├── release-snapshot.sh     – Release snapshot build + LAVA (all codenames)
    ├── release-release.sh      – Promote sandbox to public release
    ├── release-sources.sh      – Build and publish sources tarball
    ├── snapshot-container.sh   – Build + publish AGL Docker worker container
    ├── pre-fetch.sh            – Pre-fetch download mirror
    ├── daily-doc-update.sh     – Build + publish AGL docs
    └── ci-management-verify.sh – JJB verify + packer validate/build
```

## Quick start

```bash
# 1. Build the container image
cd new-container
docker build -t agl-ci:latest .

# 2. Copy and fill in secrets
cp secrets.env.example secrets.env
$EDITOR secrets.env

# 3. Run a job
docker run --rm \
  --env-file secrets.env \
  -v /path/to/ssh_download:/run/secrets/ssh_download:ro \
  -v /mnt/tank:/mnt/tank \
  -v $(pwd)/workspace:/workspace \
  agl-ci:latest \
  /new-container/jobs/snapshot-container.sh
```

## Library rules

- All files under `lib/` define **functions only** – no side effects at source time.
- Each function is named after its concern: `repo_init_sync`, `run_aglsetup`, `bitbake_image`, etc.
- State shared between steps is passed through **exported env vars** (same as the
  original Jenkins concatenation, but now explicit and traceable).
- Job entrypoints under `jobs/` source the necessary lib files and call functions
  in order. Read them top-to-bottom to understand the full pipeline.

## JJB→container mapping

| JJB include chain step | lib/ function |
|---|---|
| `include-agl-header.sh` | `init_env` in `00-env.sh` |
| `include-agl-repo.sh` | `repo_init_sync` in `10-repo.sh` |
| `include-agl-select.sh` | `repo_select` in `20-select.sh` |
| `include-agl-source-aglsetup.sh` | `run_aglsetup` in `30-aglsetup.sh` |
| `include-agl-auto-conf.sh` + fragments | `localconf_*` in `31-localconf.sh` |
| `include-agl-bitbake-image.sh` | `bitbake_image` in `40-bitbake.sh` |
| `include-agl-bitbake-sdk*.sh` | `bitbake_sdk` / `bitbake_sdk_x64only` |
| `include-agl-run-test-prepare.sh` | `lava_prepare_boardout` in `51-lava.sh` |
| `include-agl-lava-labs-prepare.sh` | `lava_find_lab` |
| `include-agl-run-test-short.sh` | `lava_create_job` |
| `include-agl-lava-jobs-submit.sh` | `lava_submit_wait` |
| `include-agl-run-test-rsync-changeid.sh` | `publish_changeid` in `50-publish.sh` |
| `include-agl-run-test-rsync-release.sh` | `publish_release` |
| Gerrit `gerrit review` SSH calls | `gerrit_vote` in `90-gerrit-review.sh` |

## Secrets

See `secrets.env.example` for the full list. Three injection mechanisms:

1. **Env vars** (`--env-file secrets.env`) – API tokens, lab credentials.
2. **SSH key files** (`-v key:/run/secrets/ssh_name:ro`) – SSH identities.
3. **Cloud config** (`-v cloudenv:/run/secrets/cloudenv:ro`) – Packer cloud creds.

`lib/00-ssh.sh:setup_ssh` reads the key paths from env, copies them into
`~/.ssh/`, sets correct permissions, and starts `ssh-agent` when multiple
identities are needed.

## GitHub Actions

See `.github/workflows/README.md` for the full GH Actions setup including
required secrets, runner labels, and trigger mapping.
