#!/bin/sh
set -eu

cleanup() {
    rm -rf rootfs staging iso DoomLinux.iso
}

cleanup

DOOMLINUX_TEST_MODE=smoke ./DoomLinux.sh

test -f DoomLinux.iso
test -f rootfs/root/TRENCHBROOM-INSTALL.txt
test -d rootfs/bin
test -d rootfs/dev
test -d rootfs/mnt
test -d rootfs/proc
test -d rootfs/sys
test -d rootfs/tmp
grep -q "TrenchBroom" rootfs/root/TRENCHBROOM-INSTALL.txt
grep -q 'menuentry "DoomLinux"' iso/boot/grub/grub.cfg

SUMMARY_PATH=tests/artifacts/smoke-summary.txt
if [ -f "$SUMMARY_PATH" ]; then
    echo "──── Smoke Summary ────"
    cat "$SUMMARY_PATH"
fi

cleanup
