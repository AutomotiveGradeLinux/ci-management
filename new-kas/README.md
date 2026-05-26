# AGL kas build

Build AGL images using [kas](https://kas.readthedocs.io/) — a declarative
Yocto setup tool that replaces `repo` + `aglsetup.sh` with composable YAML
config files.

## Install kas

```bash
pip install kas
# or with pipx
pipx install kas
```

No local kas install needed if you use `kas-container` (see below).

---

## Config composition

A build is described by combining config files with `:`:

```
kas build <branch>:<machine>:<feature...>:<image>
```

| Slot | Files | Selects |
|---|---|---|
| branch | `kas/master.yml`, `kas/trout.yml`, `kas/salmon.yml`, `kas/unagi.yml` | repo SHAs + branch |
| machine | `kas/machines/<machine>.yml` | MACHINE + BSP layers |
| features | `kas/features/<feature>.yml` (repeatable) | `require conf/include/<f>.inc` |
| image | `kas/images/<image>.yml` | bitbake target |

---

## Quick start

```bash
# qemux86-64, master, full IVI flutter image
kas build kas/master.yml:kas/machines/qemux86-64.yml:kas/features/agl-demo.yml:kas/features/agl-app-framework.yml:kas/features/agl-devel.yml:kas/features/agl-flutter.yml:kas/features/agl-kuksa-val.yml:kas/features/agl-netboot.yml:kas/features/agl-pipewire.yml:kas/features/agl-selinux.yml:kas/images/agl-ivi-demo-flutter.yml
```

Use `KAS_FILES` to avoid repeating the chain:

```bash
export KAS_FILES="kas/master.yml:kas/machines/qemux86-64.yml:kas/features/agl-demo.yml:kas/features/agl-app-framework.yml:kas/features/agl-devel.yml:kas/features/agl-flutter.yml:kas/features/agl-kuksa-val.yml:kas/features/agl-netboot.yml:kas/features/agl-pipewire.yml:kas/features/agl-selinux.yml:kas/images/agl-ivi-demo-flutter.yml"
kas build
```

---

## Using kas-container (Docker, no local kas install)

`kas-container` is a shell script that runs kas inside the official Docker
image. Download it once:

```bash
curl -fsSL https://raw.githubusercontent.com/siemens/kas/master/kas-container -o kas-container
chmod +x kas-container
```

Then substitute `kas` with `./kas-container` in all commands.
Pass persistent cache mounts via `KAS_CONTAINER_EXTRA_ARGS`:

```bash
export KAS_CONTAINER_EXTRA_ARGS="-v /fast-disk/sstate:/sstate-cache -v /fast-disk/downloads:/downloads"
./kas-container build "${KAS_FILES}"
```

---

## Build variants

### Trout release (19.92.0), qemux86-64

```bash
kas build kas/trout.yml:kas/machines/qemux86-64.yml:kas/features/agl-demo.yml:kas/features/agl-devel.yml:kas/features/agl-flutter.yml:kas/images/agl-ivi-demo-flutter.yml
```

### Minimal image (no graphics)

```bash
kas build kas/master.yml:kas/machines/qemux86-64.yml:kas/features/agl-devel.yml:kas/images/agl-image-minimal.yml
```

### ARM64 QEMU

```bash
kas build kas/master.yml:kas/machines/qemuarm64.yml:kas/features/agl-demo.yml:kas/features/agl-devel.yml:kas/features/agl-flutter.yml:kas/images/agl-ivi-demo-flutter.yml
```

### Raspberry Pi 4

```bash
kas build kas/master.yml:kas/machines/raspberrypi4.yml:kas/features/agl-demo.yml:kas/features/agl-devel.yml:kas/features/agl-flutter.yml:kas/images/agl-ivi-demo-flutter.yml
```

### H3ULCB (Renesas, netboot / no graphics)

```bash
kas build kas/master.yml:kas/machines/h3ulcb.yml:kas/features/agl-netboot.yml:kas/features/agl-devel.yml:kas/images/agl-demo-platform.yml
```

### M3ULCB, unagi release

```bash
kas build kas/unagi.yml:kas/machines/m3ulcb.yml:kas/features/agl-netboot.yml:kas/features/agl-devel.yml:kas/images/agl-demo-platform.yml
```

---

## Interactive shell (bitbake ready)

```bash
kas shell kas/master.yml:kas/machines/qemux86-64.yml:kas/features/agl-demo.yml:kas/features/agl-devel.yml:kas/features/agl-flutter.yml:kas/images/agl-ivi-demo-flutter.yml
```

Inside the shell:

```bash
bitbake agl-ivi-demo-flutter
bitbake -c devshell wayland
bitbake -c cleansstate <recipe> && bitbake <recipe>
bitbake --runall=fetch agl-ivi-demo-flutter
```

---

## Fetch sources only (no build)

```bash
kas checkout kas/master.yml:kas/machines/qemux86-64.yml:kas/features/agl-demo.yml:kas/features/agl-flutter.yml:kas/images/agl-ivi-demo-flutter.yml
```

---

## Testing a Gerrit patch

```bash
# 1. Fetch repos
kas checkout "${KAS_FILES}"

# 2. Apply the patch in the relevant repo
CHANGE=12345
PATCHSET=3
PROJECT_PATH=meta-agl   # or meta-agl-demo, meta-agl-devel, bsp/meta-agl-refhw

cd "${KAS_WORK_DIR:-${PWD}}/${PROJECT_PATH}"
git fetch https://gerrit.automotivelinux.org/gerrit/AGL/${PROJECT_PATH} \
  refs/changes/$(printf '%02d' $((CHANGE % 100)))/${CHANGE}/${PATCHSET}
git checkout FETCH_HEAD
cd -

# 3. Build without re-fetching
kas build --skip-checkout "${KAS_FILES}"
```

---

## Override download / sstate paths

```bash
DL_DIR=/mnt/cache/downloads SSTATE_DIR=/mnt/cache/sstate kas build "${KAS_FILES}"
```

Defaults in `kas/common.yml`: `/downloads` and `/sstate-cache`
(the kas-container standard mount points).

---

## File layout

```
new-kas/
├── README.md
└── kas/
    ├── common.yml              — DISTRO=agl, cache paths, parallelism
    ├── master.yml              — all repos at master SHAs + all layers
    ├── trout.yml               — trout/19.92.0 SHAs
    ├── salmon.yml              — salmon/18.92.0 SHAs (no meta-lts-mixins_rust)
    ├── unagi.yml               — unagi/20.92.0 SHAs
    ├── machines/
    │   ├── qemux86-64.yml      — MACHINE + ext4 for runqemu
    │   ├── qemuarm64.yml
    │   ├── qemuarm.yml
    │   ├── raspberrypi4.yml    — MACHINE=raspberrypi4-64 + meta-raspberrypi BSP
    │   ├── raspberrypi5.yml    — MACHINE=raspberrypi5 + meta-raspberrypi BSP
    │   ├── h3ulcb.yml          — MACHINE=h3ulcb + Renesas BSP layers
    │   └── m3ulcb.yml          — MACHINE=m3ulcb + Renesas BSP layers
    ├── features/
    │   ├── agl-demo.yml        — require conf/include/agl-demo.inc
    │   ├── agl-devel.yml
    │   ├── agl-app-framework.yml
    │   ├── agl-flutter.yml     — + TOOLCHAIN_HOST_TASK nativesdk-flutter-sdk
    │   ├── agl-kuksa-val.yml
    │   ├── agl-netboot.yml
    │   ├── agl-pipewire.yml
    │   ├── agl-selinux.yml
    │   └── agl-ci.yml          — AGL CI mirrors, prserv, hashserv (infra use)
    └── images/
        ├── agl-ivi-demo-flutter.yml
        ├── agl-demo-platform.yml
        └── agl-image-minimal.yml
```

---

## Adding a new machine

Create `kas/machines/<machine>.yml`:

```yaml
header:
  version: 14

machine: <yocto-machine-name>

bblayers_conf_header:
  bsp: |
    BBLAYERS += "${TOPDIR}/../bsp/meta-<bsp>"

local_conf_header:
  machine_conf: |
    require conf/include/agl_<machine>.inc
```

## Adding a new feature

Create `kas/features/<feature>.yml`:

```yaml
header:
  version: 14

local_conf_header:
  agl_feature: |
    require conf/include/agl-<feature>.inc
```
