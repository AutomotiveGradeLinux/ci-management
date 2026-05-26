# AGL local CI build

Build and run an AGL image on your workstation — no Gerrit account, SSH keys,
or VPN access needed for a plain branch build.

---

## Exact steps to configure and run

All commands below are run from the `new-container-improved/` directory.

### Step 1 — Create local cache directories

```bash
mkdir -p workspace sstate downloads
```

These persist across builds. Put them on a fast disk if possible.
`workspace/` holds the full source tree + build output (~50-100 GB).
`sstate/` and `downloads/` are the Yocto caches (reused between builds).

### Step 2 — Copy and edit the config file

```bash
cp config.env.example config.env
```

Open `config.env` and set at minimum:

```bash
# Target machine — leave as-is for QEMU x86-64 (easiest)
MACHINE=qemux86-64

# AGL branch to build
AGL_BRANCH=master

# Image recipe
AGL_IMAGE=agl-ivi-demo-flutter

# AGL features passed to aglsetup.sh
AGL_FEATURES=agl-demo agl-devel agl-netboot
```

All other variables have sensible defaults. `build.sh` auto-sources `config.env`
from the same directory, so no manual `source` is needed.

### Step 3 — Build the Docker image (once)

```bash
docker build -t agl-build-container .
```

This takes ~2 minutes. Only needed once (or after a `Dockerfile` change).

### Step 4 — Run the build

```bash
docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  --env-file config.env \
  agl-build-container
```

**First run**: 4–8 hours (downloads all sources and compiles everything from scratch).
**Subsequent runs** (warm sstate): 10–30 minutes.

The built images land in:

```
workspace/src/output/tmp/deploy/images/qemux86-64/
```

### Step 5 — Boot the image

Run this on the **host** (not inside the container):

```bash
./run.sh
```

This locates `runqemu` inside the build tree automatically. Login: `root` (no password). Exit QEMU with `Ctrl-A X`.

---

## Prerequisites

- Docker (any recent version)
- ~100 GB free disk space
- `/dev/kvm` for fast QEMU (optional but strongly recommended on Linux)

---

## Building

### Default build — master branch, qemux86-64

```bash
docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  --env-file config.env \
  agl-build-container
```

### Build a specific AGL release branch

```bash
# Trout (latest stable at time of writing)
docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  -e AGL_BRANCH=trout \
  --env-file config.env \
  agl-build-container

# Salmon
docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  -e AGL_BRANCH=salmon \
  --env-file config.env \
  agl-build-container
```

### Override machine on the command line (no config.env edit needed)

```bash
# ARM 64-bit QEMU
docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  -e MACHINE=qemuarm64 \
  --env-file config.env \
  agl-build-container

# Raspberry Pi 4
docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  -e MACHINE=raspberrypi4 \
  --env-file config.env \
  agl-build-container

# Renesas H3 (no graphics)
docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  -e MACHINE=h3ulcb-nogfx \
  --env-file config.env \
  agl-build-container
```

### Build a minimal image instead of the full demo platform

```bash
docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  -e AGL_IMAGE=agl-image-minimal \
  -e AGL_FEATURES="agl-netboot agl-devel" \
  --env-file config.env \
  agl-build-container
```

### Build image + cross-SDK in one pass

```bash
docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  -e BUILD_SDK=1 \
  --env-file config.env \
  agl-build-container
# SDK installer appears in workspace/src/output/tmp/deploy/sdk/
```

### Tune parallelism to your machine

```bash
# 16-core workstation
docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  -e BB_NUMBER_THREADS=16 \
  -e PARALLEL_MAKE="-j16" \
  --env-file config.env \
  agl-build-container

# Laptop — leave headroom for the desktop
docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  -e BB_NUMBER_THREADS=4 \
  -e PARALLEL_MAKE="-j4" \
  --env-file config.env \
  agl-build-container
```

### Limit Docker CPU and RAM (useful on shared machines)

```bash
docker run --rm \
  --cpus="8" \
  --memory="16g" \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  --env-file config.env \
  agl-build-container
```

### Keep the build log in a file

```bash
docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  --env-file config.env \
  agl-build-container 2>&1 | tee build-$(date +%Y%m%d-%H%M).log
```

---

## Testing a Gerrit patch

### Via config.env (persistent)

```bash
# Add to config.env:
GERRIT_PROJECT=AGL/meta-agl
GERRIT_CHANGE_NUMBER=12345
GERRIT_PATCHSET_NUMBER=3
```

### Inline — no config.env change

```bash
docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  -e GERRIT_PROJECT=AGL/meta-agl \
  -e GERRIT_CHANGE_NUMBER=12345 \
  -e GERRIT_PATCHSET_NUMBER=3 \
  --env-file config.env \
  agl-build-container
```

### Test a meta-agl-demo patch

```bash
docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  -e GERRIT_PROJECT=AGL/meta-agl-demo \
  -e GERRIT_CHANGE_NUMBER=45678 \
  -e GERRIT_PATCHSET_NUMBER=1 \
  --env-file config.env \
  agl-build-container
```

### Test a meta-agl-devel patch

```bash
docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  -e GERRIT_PROJECT=AGL/meta-agl-devel \
  -e GERRIT_CHANGE_NUMBER=99001 \
  -e GERRIT_PATCHSET_NUMBER=2 \
  --env-file config.env \
  agl-build-container
```

The patch is applied with `repo download` after the initial sync, on top of
the current branch HEAD. Remove the three `GERRIT_*` vars to go back to a
plain branch build.

---

## Iterating on local changes

### Re-run bitbake only (skip repo sync)

After making changes inside `workspace/src/meta-agl/` (or any other layer):

```bash
SKIP_REPO_SYNC=1 docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  --env-file config.env \
  agl-build-container
```

### Interactive shell inside the container

Drop in and run bitbake commands directly — useful for debugging:

```bash
docker run --rm -it \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  --env-file config.env \
  --entrypoint bash \
  agl-build-container
```

Inside the container:

```bash
# Bootstrap the environment
source /agl-ci/lib/env.sh && init_env
source /agl-ci/lib/repo.sh
source /agl-ci/lib/aglsetup.sh && run_aglsetup
cd /workspace/src/output

# Build the image
bitbake agl-demo-platform

# Build a single recipe
bitbake wayland

# Check why a recipe was rebuilt
bitbake -e wayland | grep ^SRC_URI

# Show the task graph for a recipe
bitbake -g agl-demo-platform && cat task-depends.dot | head -40

# Force a clean rebuild of one recipe
bitbake -c cleansstate wayland && bitbake wayland

# List all available images
bitbake-layers show-recipes "*-image-*" 2>/dev/null | grep '^  '

# Fetch sources only (no build — useful to pre-warm the downloads cache)
bitbake --runall=fetch agl-demo-platform

# Inspect the build environment for a recipe
bitbake -e agl-demo-platform | grep ^DISTRO_FEATURES

# Show which recipe provides a package
bitbake -e agl-demo-platform | grep ^IMAGE_INSTALL
```

### Edit a layer file and rebuild without losing sstate

```bash
# On the host, edit the source directly:
$EDITOR workspace/src/meta-agl/recipes-platform/images/agl-demo-platform.bb

# Then rebuild — only changed tasks re-run:
SKIP_REPO_SYNC=1 docker run --rm \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  --env-file config.env \
  agl-build-container
```

---

## Interactive shell

`shell.sh` drops you into a bash prompt inside the build container with all
cache volumes and environment variables already wired up.

### Plain shell (fastest — no repo sync or aglsetup)

```bash
./shell.sh
```

The source tree and build output in `workspace/` are live-mounted, so any
edits you make on the host are immediately visible inside the container.

### Bootstrapped shell (repo sync + aglsetup run first)

```bash
./shell.sh --bootstrap
```

This runs `repo sync` and `aglsetup.sh` before handing you the prompt, so
`bitbake` is ready to use immediately:

```bash
# Inside the container after --bootstrap:
bitbake agl-ivi-demo-flutter
bitbake -c devshell <recipe>
bitbake -e <recipe> | grep ^SRC_URI
bitbake -c cleansstate <recipe> && bitbake <recipe>
```

### Override machine

```bash
MACHINE=qemuarm64 ./shell.sh --bootstrap
```

### What you can do inside

```bash
# Build the default image
bitbake agl-ivi-demo-flutter

# Build a single recipe
bitbake wayland

# Open a development shell for a recipe (drops into its build dir)
bitbake -c devshell wayland

# List all image recipes
bitbake-layers show-recipes "*-image-*" 2>/dev/null | grep '^  '

# Force a clean rebuild of one recipe
bitbake -c cleansstate wayland && bitbake wayland

# Fetch all sources without building (pre-warm downloads cache)
bitbake --runall=fetch agl-ivi-demo-flutter

# Inspect build variables for a recipe
bitbake -e agl-ivi-demo-flutter | grep ^DISTRO_FEATURES

# Show the task dependency graph
bitbake -g agl-ivi-demo-flutter && cat task-depends.dot | head -40
```

---

## Running the image

Run `./run.sh` on the **host** (not inside the container) — it needs display
access and `/dev/kvm`.

### Serial console (default — works everywhere)

```bash
./run.sh
# Login: root (no password)
# Exit QEMU: Ctrl-A X
```

### Graphical output (SDL window)

```bash
GRAPHICS=1 ./run.sh
```

### Without KVM (slower; works inside a VM or CI runner without /dev/kvm)

```bash
KVM=0 ./run.sh
```

### Networked via slirp (user-mode, no tap device or root needed)

```bash
./run.sh -- slirp
# SSH into the image (QEMU forwards guest port 22 to host 2222):
ssh -p 2222 root@localhost
```

### Networked via tap (full Ethernet, requires sudo / CAP_NET_ADMIN)

```bash
./run.sh -- tap
```

### Increase RAM for the QEMU guest

```bash
./run.sh -- qemuparams="-m 2048"
```

### Run a specific image file (not the latest)

```bash
runqemu \
  workspace/src/output/tmp/deploy/images/qemux86-64/agl-demo-platform-qemux86-64.ext4 \
  nographics serialstdio kvm
```

### Pass KVM device into the container and run there (advanced)

```bash
docker run --rm -it \
  --device /dev/kvm \
  -v $(pwd)/workspace:/workspace \
  --env-file config.env \
  --entrypoint bash \
  agl-build-container

# Inside container:
source /workspace/src/output/oe-init-build-env /workspace/src/output
runqemu agl-demo-platform nographics serialstdio kvm
```

---

## Cache management

| Host path | Container path | Contents |
|---|---|---|
| `./downloads` | `/downloads` | Bitbake source tarballs and git mirrors |
| `./sstate` | `/sstate-cache` | Shared state cache (compiled artefacts per machine+branch) |
| `./workspace` | `/workspace` | Source tree + full build output |

### Check cache size

```bash
du -sh downloads/ sstate/ workspace/
```

### Share the downloads cache across multiple checkouts

```bash
# Point both projects at the same host directory:
docker run --rm \
  -v /mnt/big-disk/agl-downloads:/downloads \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  --env-file config.env \
  agl-build-container
```

### Prune stale sstate entries (reclaim disk space)

```bash
# Inside an interactive container session:
source /workspace/src/output/oe-init-build-env /workspace/src/output
# Remove sstate entries older than 30 days
find /sstate-cache -name "*.tgz" -mtime +30 -delete
```

### Wipe the build output but keep downloads and sstate

```bash
rm -rf workspace/src/output/tmp
# Next build re-uses sstate — much faster than a from-scratch build
```

### Full clean slate (keep only sources)

```bash
rm -rf workspace/src/output
# Leaves .repo and source layers intact; sstate still applies on next build
```

---

## Docker image management

### Build with a custom tag

```bash
docker build -t agl-build-container:master .
docker build -t agl-build-container:trout .
```

### Rebuild the Docker image without cache (after Dockerfile changes)

```bash
docker build --no-cache -t agl-build-container .
```

### Export the Docker image for use on another machine

```bash
docker save agl-build-container | gzip > agl-build-container.tar.gz
# On the other machine:
gunzip -c agl-build-container.tar.gz | docker load
```

### Run with a non-root host user (avoid root-owned output files)

```bash
docker run --rm \
  --user $(id -u):$(id -g) \
  -v $(pwd)/workspace:/workspace \
  -v $(pwd)/sstate:/sstate-cache \
  -v $(pwd)/downloads:/downloads \
  --env-file config.env \
  agl-build-container
```

---

## File layout

```
new-container-improved/
├── Dockerfile          – minimal Ubuntu 22.04 build container
├── build.sh            – main entrypoint (repo → aglsetup → bitbake)
├── run.sh              – launch built image with runqemu (run on host)
├── shell.sh            – drop into an interactive shell inside the container
├── config.env.example  – all configuration options with comments
└── lib/
    ├── env.sh          – variable defaults and normalisation
    ├── repo.sh         – repo init / sync / patch apply
    ├── aglsetup.sh     – install-buildtools + aglsetup.sh + cache wiring
    ├── localconf.sh    – auto.conf / local.conf additions
    └── bitbake.sh      – bitbake_image / bitbake_sdk
```

## Configuration reference

| Variable | Default | Meaning |
|---|---|---|
| `MACHINE` | `qemux86-64` | Target board (see supported machines below) |
| `AGL_BRANCH` | `master` | AGL release branch (`master`, `trout`, `salmon`, …) |
| `AGL_FEATURES` | `agl-demo agl-devel agl-netboot` | Features passed to `aglsetup.sh` |
| `AGL_IMAGE` | `agl-ivi-demo-flutter` | Bitbake image recipe to build |
| `BB_NUMBER_THREADS` | CPU count | Parallel bitbake threads |
| `PARALLEL_MAKE` | `-j<CPU count>` | make parallelism inside recipes |
| `BUILD_SDK` | `0` | `1` = also build the cross-SDK after the image |
| `SKIP_REPO_SYNC` | `0` | `1` = skip repo sync, use existing source tree |
| `GERRIT_PROJECT` | (empty) | Project containing the patch, e.g. `AGL/meta-agl` |
| `GERRIT_CHANGE_NUMBER` | (empty) | Gerrit change number |
| `GERRIT_PATCHSET_NUMBER` | (empty) | Gerrit patchset number |

### Supported machines

| `MACHINE` | How to run the result |
|---|---|
| `qemux86-64` | `./run.sh` ← default, recommended for local dev |
| `qemuarm64` | `./run.sh` |
| `qemuarm` | `./run.sh` |
| `raspberrypi4` | Flash `tmp/deploy/images/raspberrypi4-64/*.wic.bz2` to SD card |
| `raspberrypi5` | Same |
| `h3ulcb-nogfx` | Flash or boot via TFTP/NFS |
| `m3ulcb-nogfx` | Same |

## Relation to new-container/

`new-container/` is the full CI pipeline including LAVA, rsync publishing,
Gerrit voting, and GitHub Actions workflows — used on the AGL build servers.

`new-container-improved/` strips all of that away and focuses on what a
developer needs: clone → build → runqemu, with persistent local caches.
The same `lib/` function pattern is used so it is easy to lift pieces back
into the full pipeline when needed.
