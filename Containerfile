# Custom Bluefin DX image with Slimbook laptop support

ARG BASE_IMAGE=ghcr.io/ublue-os/bluefin-dx

FROM ${BASE_IMAGE}:stable

# Get kernel version from the base image
RUN KERNEL_VERSION=$(rpm -qa kernel --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}') && \
    echo "Building for kernel: ${KERNEL_VERSION}" && \
    echo "${KERNEL_VERSION}" > /tmp/kernel-version.txt

# Install REAL kernel-devel to enable akmod building
# Bluefin has a stub kernel-devel (RPM registered but no files), so we need to:
# 1. Remove the stub entry from the RPM database
# 2. Reinstall the actual package with files
RUN KVER=$(cat /tmp/kernel-version.txt) && \
    echo "Removing stub kernel-devel..." && \
    rpm -e --nodeps kernel-devel-${KVER} || true && \
    echo "Installing real kernel-devel..." && \
    dnf install -y kernel-devel-${KVER} && \
    echo "Verifying kernel headers exist..." && \
    ls -la /usr/src/kernels/

# Add Slimbook repository
RUN dnf config-manager addrepo --from-repofile=https://download.opensuse.org/repositories/home:/Slimbook/Fedora_$(rpm -E %fedora)/home:Slimbook.repo

# Install Slimbook packages
# Use noscripts to prevent akmod post-install from running as root (which fails)
RUN dnf install -y --setopt=tsflags=noscripts \
    slimbook-meta-common \
    slimbook-meta-evo \
    slimbook-meta-gnome \
    slimbook-service \
    slimbook-qc71-kmod \
    slimbook-qc71-kmod-common

# Build the kernel module RPM as non-root user, then install as root
# akmods refuses to build as root, but needs root to install - so we split the steps
# Need to ensure akmods user has writable home/working directory for rpmbuild
RUN KVER=$(cat /tmp/kernel-version.txt) && \
    echo "Building akmod RPM for kernel ${KVER}..." && \
    SRPM=$(ls /usr/src/akmods/slimbook-qc71-kmod-*.src.rpm) && \
    mkdir -p /var/lib/akmods && chown akmods:akmods /var/lib/akmods && \
    su -s /bin/bash akmods -c "cd /var/lib/akmods && HOME=/var/lib/akmods akmodsbuild --target $(uname -m) --kernels ${KVER} ${SRPM}" && \
    echo "Installing built kmod RPM..." && \
    dnf install -y /var/lib/akmods/kmod-slimbook-qc71-${KVER}-*.rpm

# Verify the kernel module was built
RUN ls -la /usr/lib/modules/$(cat /tmp/kernel-version.txt)/extra/ || echo "Checking module location..."

# Clean up kernel-devel to save space (module is already compiled)
RUN dnf remove -y kernel-devel && dnf clean all

# Clean up temp files
RUN rm -f /tmp/kernel-version.txt

# Standard ostree container commit
RUN ostree container commit
