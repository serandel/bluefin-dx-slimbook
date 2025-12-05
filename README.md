# Bluefin DX Slimbook

Custom [Bluefin DX](https://projectbluefin.io/) image with [Slimbook](https://slimbook.com/) laptop support.

## What's included

This image adds the following Slimbook packages on top of Bluefin DX:

- `slimbook-meta-gnome` - Meta package for GNOME desktop integration
- `slimbook-service` - Slimbook system service
- `slimbook-qc71-kmod` - Kernel module for QC71-based laptops (fan control, lightbar, performance modes)
- `slimbook-qc71-kmod-common` - Common files for the QC71 kernel module

## Usage

### Rebase from Bluefin DX

```bash
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/serandel/bluefin-dx-slimbook:stable
```

Then reboot.

### Updates

Updates work the same as regular Bluefin - the image is rebuilt automatically when upstream Bluefin updates.

## Building locally

```bash
podman build -t bluefin-dx-slimbook .
```

## Why this exists

Bluefin (and other Fedora Atomic distributions) can't build akmods at install time because they don't ship real kernel-devel headers. This image builds the Slimbook kernel modules during the container build process, where we have full access to install kernel-devel temporarily.

See also: [ublue-os/akmods#431](https://github.com/ublue-os/akmods/issues/431) - Request to add Slimbook support to the official uBlue akmods.

## Credits

- [Universal Blue](https://universal-blue.org/) for Bluefin
- [Slimbook](https://slimbook.com/) for their Linux laptops and open-source drivers
