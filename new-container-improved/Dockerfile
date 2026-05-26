FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    # Yocto/Poky host dependencies
    gawk wget git diffstat unzip texinfo gcc build-essential \
    chrpath socat cpio python3 python3-pip python3-pexpect \
    xz-utils debianutils iputils-ping python3-git python3-jinja2 \
    libegl1-mesa libsdl1.2-dev pylint xterm python3-subunit \
    mesa-common-dev zstd liblz4-tool file locales \
    # Network / transfer
    curl ca-certificates \
    # Misc
    make sudo tree \
    && rm -rf /var/lib/apt/lists/*

# Google repo tool
RUN curl -fsSL https://storage.googleapis.com/git-repo-downloads/repo \
    -o /usr/local/bin/repo && chmod a+x /usr/local/bin/repo

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8

# Build user (uid 1000 – matches typical developer uid, avoids root-owned artifacts)
RUN useradd -m -u 1000 -s /bin/bash build && \
    echo 'build ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Mount points for bind-mounts from the host:
#   /workspace        – per-build working directory  (required)
#   /sstate-cache     – persistent sstate cache       (recommended, speeds up rebuilds)
#   /downloads        – persistent downloads mirror   (recommended)
RUN mkdir -p /workspace /sstate-cache /downloads && \
    chown build:build /workspace /sstate-cache /downloads

USER build
WORKDIR /workspace

COPY --chown=build:build lib/   /agl-ci/lib/
COPY --chown=build:build build.sh /agl-ci/build.sh
RUN chmod +x /agl-ci/build.sh

ENTRYPOINT ["/agl-ci/build.sh"]
