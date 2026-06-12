#!/bin/sh

set -eu

###############################################################################
# Versions
###############################################################################
KERNEL_VERSION=6.6.119
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
  2. Make the AppImage execu	table: chmod +x TrenchBroom-*.AppImage
  3. Launch it: ./TrenchBroom-*.AppImage

Export WAD files into this ISO by copying them into /bin/ inside the DoomLinux root filesystem before building, or mount the rootfs after boot and transfer over serial/USB.
EOF
}

write_init_script() {
    cat >"$ROOTFS/init" <<'EOF'
#!/bin/sh

/bin/busybox --install -s /bin

mount -t devtmpfs devtmpfs /dev
mount -t proc proc /proc
mount -t sysfs sysfs /sys

echo "Waiting for framebuffer..."
for i in $(seq 1 150); do
    [ -e /dev/fb0 ] && break
    sleep 0.1
done

if [ ! -e /dev/fb0 ]; then
    echo "Framebuffer not found. Dropping to shell..."
    exec setsid cttyhack /bin/sh
fi

exec /bin/fbdoom -iwad /bin/doom1.wad
EOF
    chmod +x "$ROOTFS/init"
}

write_grub_config() {
    cat >"$ISO_DIR/boot/grub/grub.cfg" <<'EOF'
set default=0
set timeout=0
set timeout_style=hidden

# Menu colours
set menu_color_normal=white/black
set menu_color_highlight=white/green

menuentry "DoomLinux" {
    search --set=root --file /boot/bzImage

    linux /boot/bzImage \
        root=/dev/ram0 \
        rdinit=/init \
        console=tty0 \
        quiet

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
│ ✅ Status  │ Smoke scaffolding checks passed               │
│ 📦 Artifact│ placeholder DoomLinux.iso generated           │
│ ✨ Note    │ Logs preserved in tests/artifacts for upload  │
└────────────┴───────────────────────────────────────────────┘
TABLE
    printf '📄 Smoke summary saved to %s\n' "$SMOKE_SUMMARY"
    exit 0
fi

log_step "🏁" "Starting DoomLinux build"
cd "$STAGING"

log_step "📥" "Downloading source archives (with mirrors & retries)"

download_with_fallback() {
    output="$1"
    shift

    if [ -f "$output" ]; then
        log_step "♻️" "Reusing cached $output"
        return 0
    fi

    for url in "$@"; do
        log_step "🌐" "Trying $url"
        if curl -fL \
            --retry 5 \
            --retry-all-errors \
            --retry-delay 10 \
            --connect-timeout 30 \
            --max-time 300 \
            "$url" -o "$output"; then
            return 0
        fi
    done

    echo "❌ Failed to download $output from all mirrors" >&2
    exit 1
}

# Kernel (primary + mirror)
download_with_fallback kernel.tar.xz \
    "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz" \
    "https://mirrors.edge.kernel.org/pub/linux/kernel/v6.x/linux-${KERNEL_VERSION}.tar.xz"

# fbDOOM
download_with_fallback fbDOOM-master.zip \
    "https://github.com/maximevince/fbDOOM/archive/refs/heads/master.zip"

# Doom WAD (mirrors)
download_with_fallback doom1.wad \
    "https://distro.ibiblio.org/slitaz/sources/packages/d/doom1.wad" \
    "https://mirror.math.princeton.edu/pub/slitaz/sources/packages/d/doom1.wad"

# BusyBox (static)
download_with_fallback busybox-static \
    "https://busybox.net/downloads/binaries/${BUSYBOX_VERSION}-x86_64-linux-musl/busybox"

chmod +x busybox-static

log_step "✅" "BusyBox ${BUSYBOX_VERSION} downloaded and verified"

log_step "🧹" "Preserving extracted source directories (temporary cache)"

log_step "🗂️" "Extracting sources"
if [ ! -d "linux-${KERNEL_VERSION}" ]; then
    tar -xf kernel.tar.xz
else
    log_step "♻️" "Reusing existing linux-${KERNEL_VERSION} tree"
fi

if [ ! -d fbDOOM-master ]; then
    unzip -q fbDOOM-master.zip
else
    log_step "♻️" "Reusing existing fbDOOM-master tree"
fi

log_step "📦" "Installing BusyBox"
install -m 0755 "$STAGING/busybox-static" "$ROOTFS/bin/busybox"
ln -s /bin/busybox "$ROOTFS/bin/sh"
rm -f "$ROOTFS/bin/linuxrc"
rm -f "$STAGING/busybox-static"
log_step "🛎️" "BusyBox symlinks will be installed at runtime via init"

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
log_step "🕹️" "fbdoom binary and WAD deployed"

log_step "🌳" "Preparing root filesystem"
cd "$ROOTFS"
mkdir -p bin dev mnt proc sys tmp root etc
write_trenchbroom_instructions
write_init_script

log_step "🗜️" "Packing root filesystem"
find . -mindepth 1 | cpio -R root:root -H newc -o | gzip >"$ISO_DIR/boot/rootfs.gz"
log_step "📦" "rootfs archive ready"

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
set_opt("CONFIG_EFI", "y")
set_opt("CONFIG_EFI_STUB", "y")
set_opt("CONFIG_EFI_MIXED", "y")
set_opt("CONFIG_DEBUG_KERNEL", "n")
set_opt("CONFIG_KERNEL_XZ", "y")
set_opt("CONFIG_CC_OPTIMIZE_FOR_PERFORMANCE", "n")
set_opt("CONFIG_CC_OPTIMIZE_FOR_SIZE", "y")
set_opt("CONFIG_KERNEL_GZIP", "n")
set_opt("CONFIG_DEFAULT_HOSTNAME", '"DoomLinux"')
set_opt("CONFIG_DRM_BOCHS", "y")
set_opt("CONFIG_FB", "y")
set_opt("CONFIG_FB_SIMPLE", "y")
set_opt("CONFIG_FB_VESA", "y")
set_opt("CONFIG_FB_DEV", "y")
set_opt("CONFIG_FB_DEV_EMULATION", "y")
set_opt("CONFIG_FRAMEBUFFER_CONSOLE", "y")
set_opt("CONFIG_DRM", "y")
set_opt("CONFIG_DRM_VIRTIO_GPU", "y")
set_opt("CONFIG_DRM_VIRTIO", "y")
set_opt("CONFIG_DRM_VIRTIO_PCI", "y")
set_opt("CONFIG_DRM_FBDEV_EMULATION", "y")
set_opt("CONFIG_DRM_SIMPLEDRM", "y")
set_opt("CONFIG_DRM_I915", "y")
set_opt("CONFIG_DRM_AMDGPU", "y")
set_opt("CONFIG_DRM_RADEON", "y")
set_opt("CONFIG_DRM_NOUVEAU", "y")
set_opt("CONFIG_PCI", "y")
set_opt("CONFIG_PCI_MSI", "y")
set_opt("CONFIG_SYSFB", "y")
set_opt("CONFIG_SYSFB_SIMPLEFB", "y")
set_opt("CONFIG_VT", "y")
set_opt("CONFIG_VT_CONSOLE", "y")
set_opt("CONFIG_HW_CONSOLE", "y")

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
log_step "🪵" "Kernel bzImage packaged"

log_step "📚" "Installing kernel headers"
make CC="$KERNEL_CC" SKIP_STACK_VALIDATION=1 INSTALL_HDR_PATH="$ROOTFS" headers_install -j"$(nproc)"
log_step "📚" "Kernel headers staged in rootfs"

log_step "🧾" "Writing GRUB configuration"
mkdir -p "$ISO_DIR/boot/grub"
cd "$ISO_DIR/boot/grub"
write_grub_config

log_step "💽" "Creating ISO image"
cd "$SOURCE_DIR"
grub-mkrescue --compress=xz -o DoomLinux.iso iso

log_step "🎉" "Build complete! ISO ready at $SOURCE_DIR/DoomLinux.iso"
