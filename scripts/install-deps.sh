#!/bin/sh

set -e

print_usage() {
	cat <<EOF
Usage: $0 [--dry-run]

Installs the packages required to build and test DoomLinux.

Options:
  --dry-run   Print the packages that would be installed and exit.
  --help      Show this help message.

This script targets Debian/Ubuntu environments and requires root
privileges unless --dry-run is provided.
EOF
}

DRY_RUN=0

while [ $# -gt 0 ]; do
	case "$1" in
	--dry-run)
		DRY_RUN=1
		shift
		;;
	--help | -h)
		print_usage
		exit 0
		;;
	*)
		echo "Unknown option: $1" >&2
		print_usage >&2
		exit 1
		;;
	esac
done

APT_PACKAGES="wget make gawk gcc bc bison flex unzip rsync mtools xorriso libelf-dev libssl-dev grub-common grub-pc-bin grub-efi-amd64-bin cpio tar xz-utils file dosfstools qemu-system-x86-headless vagrant docker.io shellcheck shfmt python3 python3-pip"

if [ "$DRY_RUN" -eq 1 ]; then
	echo "The following packages would be installed:"
	for pkg in $APT_PACKAGES; do
		echo "  - $pkg"
	done
	echo
	echo "Consider complementing ISO validation with the miso tooling (https://github.com/ByteHackr/miso) for automated boot checks."
	exit 0
fi

if [ "$(id -u)" -ne 0 ]; then
	echo "Please run this script with sudo or as root (or use --dry-run)." >&2
	exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
# shellcheck disable=SC2086
set -- $APT_PACKAGES
apt-get install -y "$@"

python3 -m pip install --no-cache-dir --upgrade behave coverage >/dev/null 2>&1 || true

echo "Dependencies installed successfully."
