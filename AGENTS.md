# Repository Guidelines

## Project Structure & Module Organization
`DoomLinux.sh` orchestrates the entire build: it fetches kernel, BusyBox, and FBDoom sources, configures them, and assembles a bootable ISO. Running the script materializes three working directories in the repository root—`staging/` for downloaded sources, `rootfs/` for the initramfs tree, and `iso/boot/` for boot artifacts such as `bzImage`, `System.map`, `rootfs.gz`, and `grub.cfg`. The root `Makefile` wraps common workflows, `tests/` houses shell-based smoke checks alongside `behave` features, `docker/` provides container definitions for Ubuntu and Alpine builds, and `.github/workflows/` contains the CI that builds artifacts, runs tests, and publishes releases. Keep `README.md` aligned with the script whenever build steps or dependency versions change.

## Build, Test, and Development Commands
- `sudo apt install wget make gawk gcc bc bison flex unzip rsync mtools xorriso libelf-dev libssl-dev grub-common` prepares a Debian-based host with the documented toolchain.
- `make build` or `./DoomLinux.sh` performs a full build and emits `DoomLinux.iso`. You can override versions with `KERNEL_VERSION=... BUSYBOX_VERSION=... make build`.
- `make docker-run-ubuntu` / `make docker-run-alpine` execute the build inside preconfigured containers and leave `DoomLinux.iso` in the project root.
- `make lint` runs ShellCheck and shfmt (local tools preferred, Docker fallback).
- `make test-smoke` exercises a lightweight functional check that uses the smoke-mode build path to ensure key artifacts appear.
- `make test-bdd` installs local Python dependencies and runs the behavior-driven scenarios under `tests/features/`.
- `make test-qemu` boots `DoomLinux.iso` headlessly with QEMU (requires `qemu-system-x86_64`).
- `make test-vagrant` drives the same QEMU check from a Vagrant Docker guest (requires Vagrant + Docker access).
- `./scripts/install-deps.sh --dry-run` prints the dependency list; run without flags (as root) to install prerequisites locally.
- `qemu-system-x86_64 DoomLinux.iso` sanity-checks the image in a VM. Capture console output for review when reporting issues.
- `rm -rf rootfs staging iso DoomLinux.iso` resets the workspace for a clean rebuild; avoid running it if you need artifacts for debugging.

## Coding Style & Naming Conventions
Stick to POSIX shell so the script remains portable under `/bin/sh`. Use uppercase snake case for configurable variables (e.g., `SOURCE_DIR`, `ISO_DIR`) and lowercase for temporary locals. Favor small, linear sections over nested subshells; when introducing complex logic, wrap it in well-named functions and precede them with a brief comment describing inputs and side effects. Preserve `set -ex` for deterministic logging and immediate failure on errors. When scripting downloads, prefer quiet `wget -nc -O <target> <url>` patterns already present in the project.

## Testing Guidelines
Automated coverage spans `tests/smoke.sh` (fast functional scaffold checks), `tests/features/*.feature` (behavior-driven assertions via `behave`), and boot validation in `tests/run_qemu.sh` plus the Vagrant harness under `tests/vagrant/`. Additional scenarios in `tests/features/tooling.feature` guard the presence of `scripts/install-deps.sh`, the devcontainer setup, VS Code launch files, and README guidance (including miso recommendations). Always run `make test-smoke`; add `make test-bdd` when touching filesystem layout, docs, or workflow logic. For code that influences boot flow, run `make test-qemu` or `make test-vagrant` (the latter mirrors the CI Docker/Vagrant environment). If you touch kernel or BusyBox configuration, document the change and verify the resulting options by inspecting `.config` or running `grep CONFIG_* linux-*/.config`.

## Commit & Pull Request Guidelines
Follow the repository’s short, descriptive commit style (e.g., “Boschs display DRM added”). Keep the summary under ~60 characters, use present tense, and include focused commits for each functional change. Pull requests should link related issues, outline the motivation, list the exact commands run (`./DoomLinux.sh`, `make lint`, integration tests such as `make test-qemu`/`make test-vagrant`, devcontainer builds, install script dry-runs), and mention any new dependencies or artifacts that reviewers need to fetch. Add screenshots or serial logs if gameplay or boot output changed visibly.
