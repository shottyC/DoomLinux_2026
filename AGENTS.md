# Repository Guidelines

## Project Structure & Module Organization
`DoomLinux.sh` orchestrates the entire build: it fetches kernel, BusyBox, and FBDoom sources, configures them, and assembles a bootable ISO. Running the script materializes three working directories in the repository root—`staging/` for downloaded sources, `rootfs/` for the initramfs tree, and `iso/boot/` for boot artifacts such as `bzImage`, `System.map`, `rootfs.gz`, and `grub.cfg`. The root `Makefile` wraps common workflows, `docker/` houses container definitions for Ubuntu and Alpine builds, and `.github/workflows/` contains the CI that builds and, on releases, publishes the ISO. Keep `README.md` aligned with the script whenever build steps or dependency versions change.

## Build, Test, and Development Commands
- `sudo apt install wget make gawk gcc bc bison flex unzip rsync mtools xorriso libelf-dev libssl-dev grub-common` prepares a Debian-based host with the documented toolchain.
- `make build` or `./DoomLinux.sh` performs a full build and emits `DoomLinux.iso`. You can override versions with `KERNEL_VERSION=... BUSYBOX_VERSION=... make build`.
- `make docker-run-ubuntu` / `make docker-run-alpine` execute the build inside preconfigured containers and leave `DoomLinux.iso` in the project root.
- `qemu-system-x86_64 DoomLinux.iso` sanity-checks the image in a VM. Capture console output for review when reporting issues.
- `rm -rf rootfs staging iso DoomLinux.iso` resets the workspace for a clean rebuild; avoid running it if you need artifacts for debugging.

## Coding Style & Naming Conventions
Stick to POSIX shell so the script remains portable under `/bin/sh`. Use uppercase snake case for configurable variables (e.g., `SOURCE_DIR`, `ISO_DIR`) and lowercase for temporary locals. Favor small, linear sections over nested subshells; when introducing complex logic, wrap it in well-named functions and precede them with a brief comment describing inputs and side effects. Preserve `set -ex` for deterministic logging and immediate failure on errors. When scripting downloads, prefer quiet `wget -nc -O <target> <url>` patterns already present in the project.

## Testing Guidelines
No automated test harness exists—every change should be validated by building the ISO and booting it in QEMU or real hardware. Confirm that `init` launches `fbdoom` and drops to a BusyBox shell afterward. If you touch kernel or BusyBox configuration, document the change and verify the resulting options by inspecting `.config` or running `grep CONFIG_* linux-*/.config`.

## Commit & Pull Request Guidelines
Follow the repository’s short, descriptive commit style (e.g., “Boschs display DRM added”). Keep the summary under ~60 characters, use present tense, and include focused commits for each functional change. Pull requests should link related issues, outline the motivation, list the exact commands run (`./DoomLinux.sh`, QEMU invocation, hardware smoke tests), and mention any new dependencies or artifacts that reviewers need to fetch. Add screenshots or serial logs if gameplay or boot output changed visibly.
