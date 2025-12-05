# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a custom OCI container image that extends Bluefin DX (a Fedora Atomic desktop distribution) with Slimbook laptop hardware support. The image is built and published automatically via GitHub Actions.

**Key challenge**: Fedora Atomic distributions ship stub kernel-devel packages (RPM database entries with no files), preventing akmod kernel modules from building at install time. This project solves that by building the Slimbook kernel modules during the container build process where real kernel-devel can be temporarily installed.

## Build Commands

```bash
# Local build
podman build -t bluefin-dx-slimbook .

# Build with specific Slimbook package digest (matches CI workflow)
podman build --build-arg SLIMBOOK_DIGEST=<hash> -t bluefin-dx-slimbook .
```

## Architecture

### Build Process (Containerfile)

The build follows this critical sequence:

1. **Kernel version detection**: Extract kernel version from base image RPM database
2. **Real kernel-devel installation**: Remove stub kernel-devel RPM entry, install actual package with headers
3. **Repository setup**: Add Slimbook's openSUSE repository for the detected Fedora version
4. **Package installation**: Install Slimbook packages with `--setopt=tsflags=noscripts` (prevents root akmod builds which fail)
5. **Module building**: Build kernel modules as non-root `akmods` user (akmods refuses to run as root)
   - Build `slimbook-qc71-kmod` (fan control, lightbar, performance modes for QC71 laptops)
   - Build `slimbook-yt6801-kmod` (YT6801 Ethernet controller support)
6. **Module installation**: Install built kmod RPMs as root
7. **Cleanup**: Remove kernel-devel to reduce image size (compiled modules already in place)
8. **Branding**: Customize `/usr/lib/os-release` with Slimbook package digest for bootloader display
9. **Commit**: Run `ostree container commit` to finalize the image

### CI/CD Workflow (.github/workflows/build.yml)

The workflow implements intelligent rebuild detection:

**Check phase**:
- Detects Fedora version from base image labels
- Queries Slimbook repository for latest package versions
- Creates hash of package versions for change detection
- Compares upstream Bluefin digest and Slimbook package hash against current image labels
- Only proceeds to build if base image changed, packages updated, or force_build triggered

**Build phase**:
- Runs only if check phase outputs `should_build=true`
- Passes `SLIMBOOK_DIGEST` build arg for os-release customization
- Tags with `latest`, `stable`, Bluefin version number, and git SHA
- Adds OCI labels including base image digest and Slimbook package hash for future comparisons

**Triggers**:
- Scheduled: Twice daily (6 AM and 6 PM UTC)
- Push to main branch
- Manual workflow dispatch with optional force build flag

### Cleanup Workflow (.github/workflows/cleanup.yml)

Runs weekly to prune old container images, keeping 10 recent versions and ignoring `latest`/`stable` tags.

## Installed Packages

- `slimbook-meta-common` - Common Slimbook meta package
- `slimbook-meta-evo` - Evo series laptop support
- `slimbook-meta-gnome` - GNOME desktop integration
- `slimbook-service` - System service for Slimbook features
- `slimbook-qc71-kmod` + `slimbook-qc71-kmod-common` - QC71 laptop kernel module (fan, lightbar, performance)
- `slimbook-yt6801-kmod` + `slimbook-yt6801-kmod-common` - YT6801 Ethernet kernel module

## Important Notes

- The akmod build process **must** run as the `akmods` user, not root
- Kernel-devel is removed after build to save space - modules are pre-compiled
- The SLIMBOOK_DIGEST build arg is used for display purposes only (os-release branding)
- Base image digest and package hash are stored as OCI labels for rebuild detection
