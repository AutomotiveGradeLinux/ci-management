FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Yocto/Poky host dependencies (honister / kirkstone / scarthgap)
    gawk wget git diffstat unzip texinfo gcc build-essential \
    chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 \
    libegl1-mesa libsdl1.2-dev pylint xterm python3-subunit \
    mesa-common-dev zstd liblz4-tool file locales \
    # Network / transfer tools
    rsync openssh-client curl ca-certificates \
    # Misc
    make sudo tree \
    && rm -rf /var/lib/apt/lists/*

# Install Google repo tool
RUN curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo \
    -o /usr/local/bin/repo && chmod a+x /usr/local/bin/repo

# Install lavacli for LAVA test submissions
RUN pip3 install --no-cache-dir lavacli

# Locale needed by Bitbake
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8

# Runtime mount points
# /mnt/tank/downloads     – shared downloads mirror   (bind-mount read-write)
# /mnt/tank/sstate-mirror – shared sstate cache       (bind-mount read-write)
# /run/secrets/           – SSH keys + cloud config   (bind-mount read-only)
# /workspace              – per-job working directory (bind-mount read-write)
RUN mkdir -p /mnt/tank/downloads /mnt/tank/sstate-mirror /run/secrets /workspace

# Non-root build user (mirrors typical Jenkins slave uid)
RUN useradd -m -u 1000 -s /bin/bash build
USER build
WORKDIR /workspace

# The default entrypoint is overridden by each jobs/*.sh script:
#   docker run --rm -v ... --env-file secrets.env IMAGE /new-container/jobs/foo.sh
