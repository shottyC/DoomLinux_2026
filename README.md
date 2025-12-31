# DoomLinux ![Build and Release](https://github.com/shottyC/DoomLinux_2026/actions/workflows/build.yml/badge.svg) ![Test Suite](https://github.com/shottyC/DoomLinux_2026/actions/workflows/tests.yml/badge.svg) ![Integration](https://github.com/shottyC/DoomLinux_2026/actions/workflows/integration.yml/badge.svg) ![Reports](https://github.com/shottyC/DoomLinux_2026/actions/workflows/reports.yml/badge.svg) ![Dev Tooling](https://github.com/shottyC/DoomLinux_2026/actions/workflows/tooling.yml/badge.svg) ![Logs](https://github.com/shottyC/DoomLinux_2026/actions/workflows/logs.yml/badge.svg) ![Lint](https://github.com/shottyC/DoomLinux_2026/actions/workflows/lint.yml/badge.svg)

A single script to build a minimal live Linux operating system from source code that runs **Doom** on boot.

```bash
./DoomLinux.sh
```

This command creates a bootable **DoomLinux.iso**, suitable for USB sticks or virtual machines.

---

## ⚠️ Caution

This fork was substantively aided by interactions with ChatGPT. Please review changes carefully and treat the result as an educational system rather than a hardened distribution.

---

## Overview

DoomLinux is a self-contained Linux ISO that boots directly into **fbDOOM** using a custom Linux **6.6.119** kernel, a BusyBox-based initramfs, and GRUB. It is designed primarily for **QEMU / virtualized environments** and exists as a minimal, reproducible system build rather than a general-purpose distribution.

It intentionally avoids:

* systemd
* glibc userlands
* package managers
* networking

---

## What It Does

1. **Environment detection**

   * Builds natively on Linux when possible
   * Automatically falls back to Docker on macOS or non-Linux hosts

2. **Downloads required sources**

   * Linux kernel `6.6.119`
   * BusyBox `1.35.0` (static musl binary)
   * fbDOOM ([https://github.com/maximevince/fbDOOM](https://github.com/maximevince/fbDOOM))
   * `doom1.wad` (shareware)

3. **Builds fbDOOM**

   * Forces static linking
   * Disables SDL paths

4. **Creates a minimal root filesystem**

   * BusyBox-provided `/bin/sh`
   * Custom `/init` script
   * fbDOOM binary and WAD

5. **Builds a custom Linux kernel**

   * Framebuffer + DRM support for QEMU
   * Networking, sound, EFI disabled
   * Optimized for size

6. **Packages everything**

   * `rootfs.gz` initramfs
   * `bzImage` kernel
   * GRUB bootloader

7. **Outputs a bootable ISO**

   * `DoomLinux.iso`

---

## Features

* Boots directly into fbDOOM on a framebuffer console
* Custom-built Linux 6.6.119 kernel
* BusyBox static userland
* Minimal initramfs (`/init`, no systemd)
* GRUB-bootable ISO
* Reliable operation under QEMU (BIOS mode)
* Docker-assisted builds on non-Linux hosts
* Deterministic, single-script build process

---

## Build Dependencies

```bash
sudo apt install wget curl make gawk gcc bc bison flex unzip rsync mtools xorriso libelf-dev libssl-dev grub-common
```

Alternatively:

```bash
./scripts/install-deps.sh
./scripts/install-deps.sh --dry-run
```

---

## Makefile Shortcuts

```bash
make build
make clean
make docker-run-ubuntu
make docker-run-alpine
make lint
make test-smoke
make test-bdd
make test-qemu
make test-vagrant
make test-integration
make convert-logs
make lint-logs
make coverage-report
make reports
```

---

## Docker Builds

Two container definitions live under `docker/`:

* `Dockerfile.ubuntu` – Ubuntu-based toolchain
* `Dockerfile.alpine` – Alpine Linux alternative

Both mount the repository at `/workspace` and emit `DoomLinux.iso` back into the host checkout.

---

## Script Architecture

### Directory Layout

```
rootfs/
├── bin/        # BusyBox + fbdoom
├── dev/        # devtmpfs
├── proc/       # procfs
├── sys/        # sysfs
├── mnt/        # temporary mounts
├── tmp/        # temporary files
└── root/

staging/        # downloaded & compiled sources

iso/
└── boot/
    ├── bzImage
    ├── rootfs.gz
    ├── System.map
    └── grub/grub.cfg
```

---

## Kernel Configuration Highlights

The kernel is generated from `defconfig` and programmatically tuned:

* Framebuffer + DRM enabled
* QEMU-friendly drivers (`bochs`, `virtio-gpu`)
* Networking, sound, EFI disabled
* KASLR disabled
* Size-optimized compiler flags

---

## Init Process

The generated `/init` script:

* Installs BusyBox applets
* Mounts `/dev`, `/proc`, and `/sys`
* Waits for `/dev/fb0`
* Launches fbDOOM directly
* Falls back to a shell if framebuffer init fails

---

## Running DoomLinux

### Real Hardware

Write `DoomLinux.iso` to a USB stick and boot via BIOS.

### QEMU

```bash
qemu-system-x86_64 \
  -m 512M \
  -cdrom DoomLinux.iso \
  -boot d \
  -vga std
```

---

## Testing

* **Smoke test**:

  ```bash
  DOOMLINUX_TEST_MODE=smoke ./DoomLinux.sh
  ```

* **Behavior-driven tests**:

  ```bash
  make test-bdd
  ```

* **Boot validation**:

  ```bash
  make test-qemu
  make test-vagrant
  make test-integration
  ```

---

## Linting

```bash
make lint
```

Runs ShellCheck and shfmt locally or via Docker fallback.

---

## Developer Tooling

* VS Code Devcontainer support
* QEMU smoke tests
* Emoji-enhanced CI logs
* CSV / LaTeX report generation
* Automatic Docker fallback for non-Linux hosts
* DoomLinux supports miso integration for richer ISO boot smoke tests.

---

## TrenchBroom

TrenchBroom is not bundled. Instructions are written to:

```
/root/TRENCHBROOM-INSTALL.txt
```

inside the generated root filesystem.

---

## DoomLinux in Action

[![DoomLinux](https://img.youtube.com/vi/VaALEKWQOpg/0.jpg)](https://www.youtube.com/watch?v=VaALEKWQOpg)

---

## Disclaimer

This project is intended for educational purposes only. The author assumes no liability for misuse or damage.

---

## License

MIT License
