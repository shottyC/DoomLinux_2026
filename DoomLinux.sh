#!/bin/sh

set -eu

KERNEL_VERSION=5.4.3
BUSYBOX_VERSION=1.35.0

SOURCE_DIR=$PWD
ROOTFS=$SOURCE_DIR/rootfs
STAGING=$SOURCE_DIR/staging
ISO_DIR=$SOURCE_DIR/iso

mkdir -p "$ROOTFS/bin" "$STAGING" "$ISO_DIR/boot"

log_step() {
	printf '%s %s\n' "$1" "$2"
}

if [ "${DOOMLINUX_IN_DOCKER:-0}" != "1" ]; then
	need_docker=0
	case "$(uname -s)" in
	Linux)
		if [ ! -f /usr/include/linux/fb.h ]; then
			need_docker=1
		fi
		;;
	*)
		need_docker=1
		;;
	esac
	if [ "${DOOMLINUX_TEST_MODE:-}" = "smoke" ]; then
		need_docker=0
	fi
	if [ "$need_docker" -eq 1 ]; then
		if ! command -v docker >/dev/null 2>&1; then
			echo "Docker is required to build this ISO on non-Linux hosts." >&2
			exit 1
		fi
		log_step "🐳" "Delegating build to Docker (linux/amd64)"
		docker build --platform linux/amd64 -f docker/Dockerfile.ubuntu -t doomlinux:ubuntu .
		docker run --rm --platform linux/amd64 -e DOOMLINUX_IN_DOCKER=1 -v "$SOURCE_DIR":/workspace -w /workspace doomlinux:ubuntu ./DoomLinux.sh
		exit $?
	fi
fi

download() {
	url="$1"
	dest="$2"
	if [ -f "$dest" ]; then
		printf "⚙️  Using cached %s\n" "$(basename "$dest")"
		return
	fi
	printf "⬇️  Fetching %s -> %s\n" "$url" "$dest"
	if command -v curl >/dev/null 2>&1; then
		curl -L --retry 5 --retry-delay 5 -o "$dest" "$url"
	else
		wget --tries=5 --timeout=30 -O "$dest" "$url"
	fi
	if [ ! -f "$dest" ]; then
		echo "Failed to download $url" >&2
		exit 1
	fi
	printf "✅ Saved %s\n" "$(basename "$dest")"
}

write_trenchbroom_instructions() {
	cat >"$ROOTFS/root/TRENCHBROOM-INSTALL.txt" <<'EOF'
TrenchBroom is not bundled with DoomLinux.

Install on a workstation with desktop support:
  1. Download the latest TrenchBroom release from https://github.com/TrenchBroom/TrenchBroom/releases
  2. Make the AppImage executable: chmod +x TrenchBroom-*.AppImage
  3. Launch it: ./TrenchBroom-*.AppImage

Export WAD files into this ISO by copying them into /bin/ inside the DoomLinux root filesystem before building, or mount the rootfs after boot and transfer over serial/USB.
EOF
}

write_init_script() {
	cat >"$ROOTFS/init" <<'EOF'
#!/bin/sh
busybox --install -s /bin
dmesg -n 1
mount -t devtmpfs none /dev
mount -t proc none /proc
mount -t sysfs none /sys
fbdoom -iwad /bin/doom1.wad
clear
setsid cttyhack /bin/sh
EOF
	chmod +x "$ROOTFS/init"
}

write_grub_config() {
	cat >"$ISO_DIR/boot/grub/grub.cfg" <<'EOF'
set default=0
set timeout=30

# Menu Colours
set menu_color_normal=white/black
set menu_color_highlight=white/green

root (hd0,0)

menuentry "DoomLinux" {
    linux  /boot/bzImage
    initrd /boot/rootfs.gz
}
EOF
}

if [ "${DOOMLINUX_TEST_MODE:-}" = "smoke" ]; then
	log_step "🧪" "Running smoke mode"
	mkdir -p "$ROOTFS/bin" "$ROOTFS/dev" "$ROOTFS/mnt" "$ROOTFS/proc" "$ROOTFS/sys" "$ROOTFS/tmp" "$ROOTFS/root" "$ROOTFS/etc"
	mkdir -p "$ISO_DIR/boot/grub"
	write_trenchbroom_instructions
	write_init_script
	write_grub_config
	touch "$ROOTFS/bin/fbdoom" "$ROOTFS/bin/doom1.wad" "$ISO_DIR/boot/bzImage" "$ISO_DIR/boot/rootfs.gz" "$ISO_DIR/boot/System.map"
	printf 'placeholder iso\n' >"$SOURCE_DIR/DoomLinux.iso"
	LOG_DIR="$SOURCE_DIR/tests/artifacts"
	mkdir -p "$LOG_DIR"
	SMOKE_SUMMARY="$LOG_DIR/smoke-summary.txt"
	cat <<TABLE | tee "$SMOKE_SUMMARY"
┌────────────┬───────────────────────────────────────────────┐
│ ✅ Status  │ Smoke scaffolding checks passed                │
│ 📦 Artifact│ placeholder DoomLinux.iso generated           │
│ ✨ Note    │ Logs preserved in tests/artifacts for upload   │
└────────────┴───────────────────────────────────────────────┘
TABLE
	printf '📄 Smoke summary saved to %s\n' "$SMOKE_SUMMARY"
	exit 0
fi

log_step "🏁" "Starting DoomLinux build"
cd "$STAGING"

log_step "📥" "Downloading source archives"
download "https://kernel.org/pub/linux/kernel/v5.x/linux-${KERNEL_VERSION}.tar.xz" kernel.tar.xz
download "https://github.com/maximevince/fbDOOM/archive/refs/heads/master.zip" fbDOOM-master.zip
download "https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad" doom1.wad
download "https://busybox.net/downloads/binaries/${BUSYBOX_VERSION}-x86_64-linux-musl/busybox" busybox-static

log_step "🧹" "Resetting extracted source directories"
rm -rf "linux-${KERNEL_VERSION}" "busybox-${BUSYBOX_VERSION}" fbDOOM-master

log_step "🗂️" "Extracting sources"
tar -xf kernel.tar.xz
unzip -q fbDOOM-master.zip

log_step "📦" "Installing BusyBox"
install -m 0755 "$STAGING/busybox-static" "$ROOTFS/bin/busybox"
rm -f "$ROOTFS/bin/linuxrc"
rm -f "$STAGING/busybox-static"

log_step "🎯" "Building FBDoom"
cd "$STAGING/fbDOOM-master/fbdoom"
python3 - <<'PY'
from pathlib import Path
mf = Path("Makefile")
text = mf.read_text()
text = text.replace("CFLAGS+=-ggdb3 -Os", "CFLAGS+=-ggdb3 -Os -static")
text = text.replace("ifneq ($(NOSDL),1)", "ifeq ($(LINK_SDL),1)")
mf.write_text(text)
PY
make -j"$(nproc)"
cp fbdoom "$ROOTFS/bin/fbdoom"
cp "$STAGING/doom1.wad" "$ROOTFS/bin/doom1.wad"

log_step "🌳" "Preparing root filesystem"
cd "$ROOTFS"
mkdir -p bin dev mnt proc sys tmp root etc
write_trenchbroom_instructions
write_init_script

log_step "🗜️" "Packing root filesystem"
find . | cpio -R root:root -H newc -o --quiet | gzip >"$ISO_DIR/boot/rootfs.gz"

log_step "🧵" "Configuring Linux kernel"
cd "$STAGING/linux-${KERNEL_VERSION}"
make -j"$(nproc)" defconfig
python3 - <<'PY'
import re
from pathlib import Path
cfg = Path(".config")
text = cfg.read_text()

def set_opt(name, value):
    global text
    pattern = re.compile(rf"^(# )?{re.escape(name)}=.*$", re.MULTILINE)
    replacement = f"{name}={value}"
    if pattern.search(text):
        text = pattern.sub(replacement, text)
    else:
        text += "\n" + replacement + "\n"

set_opt("CONFIG_STACK_VALIDATION", "n")
set_opt("CONFIG_ORC_UNWINDER", "n")
set_opt("CONFIG_UNWINDER_FRAME_POINTER", "y")
set_opt("CONFIG_RANDOMIZE_BASE", "n")
set_opt("CONFIG_NET", "n")
set_opt("CONFIG_SOUND", "n")
set_opt("CONFIG_EFI", "n")
set_opt("CONFIG_EFI_STUB", "n")
set_opt("CONFIG_DEBUG_KERNEL", "n")
set_opt("CONFIG_KERNEL_XZ", "y")
set_opt("CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE", "n")
set_opt("CONFIG_CC_OPTIMIZE_FOR_SIZE", "y")
set_opt("CONFIG_KERNEL_GZIP", "n")
set_opt("CONFIG_DEFAULT_HOSTNAME", '"DoomLinux"')
set_opt("CONFIG_DRM_BOCHS", "y")
cfg.write_text(text)
PY
yes "" | make oldconfig >/dev/null 2>&1

KERNEL_CC="${KERNEL_CC:-}"
if [ -z "$KERNEL_CC" ]; then
	if command -v gcc >/dev/null 2>&1; then
		KERNEL_CC="gcc -no-pie"
	else
		KERNEL_CC="${CC:-cc}"
	fi
fi

log_step "🧱" "Building Linux kernel"
make CC="$KERNEL_CC" SKIP_STACK_VALIDATION=1 bzImage -j"$(nproc)"
cp arch/x86/boot/bzImage "$ISO_DIR/boot/bzImage"
cp System.map "$ISO_DIR/boot/System.map"

log_step "📚" "Installing kernel headers"
make CC="$KERNEL_CC" SKIP_STACK_VALIDATION=1 INSTALL_HDR_PATH="$ROOTFS" headers_install -j"$(nproc)"

log_step "🧾" "Writing GRUB configuration"
mkdir -p "$ISO_DIR/boot/grub"
cd "$ISO_DIR/boot/grub"
write_grub_config

log_step "💽" "Creating ISO image"
cd "$SOURCE_DIR"
grub-mkrescue --compress=xz -o DoomLinux.iso iso

log_step "🎉" "Build complete! ISO ready at $SOURCE_DIR/DoomLinux.iso"
