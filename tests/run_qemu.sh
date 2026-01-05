#!/bin/bash
set -euo pipefail

ISO_PATH=${1:-DoomLinux.iso}
if [ ! -f "$ISO_PATH" ]; then
    echo "ISO not found: $ISO_PATH" >&2
    exit 1
fi

LOG_PATH=${QEMU_LOG:-tests/artifacts/qemu.log}
SUMMARY_PATH=${QEMU_SUMMARY:-tests/artifacts/qemu-summary.txt}
QEMU_TIMEOUT=${QEMU_TIMEOUT:-90}
QEMU_ARGS=${QEMU_ARGS:--m 512M -vga std}

# Convert QEMU_ARGS string to array
# shellcheck disable=SC2206
QEMU_ARGS_ARRAY=($QEMU_ARGS)

# Detect CI or headless environment and force headless mode
if [ "${CI:-false}" = "true" ] || [ -z "${DISPLAY:-}" ]; then
    echo "Running in CI/headless mode: enabling -nographic"
    QEMU_ARGS_ARRAY+=(-nographic)
fi

mkdir -p "$(dirname "$LOG_PATH")"
mkdir -p "$(dirname "$SUMMARY_PATH")"

echo "Launching QEMU with ISO $ISO_PATH"
set +e
timeout "$QEMU_TIMEOUT" qemu-system-x86_64 -cdrom "$ISO_PATH" -boot d "${QEMU_ARGS_ARRAY[@]}" >"$LOG_PATH" 2>&1
status=$?
set -e

if [ "$status" -ne 0 ] && [ "$status" -ne 124 ]; then
    echo "QEMU exited with status $status"
    cat "$LOG_PATH" || true
    exit "$status"
fi

if ! grep -qi "Linux version" "$LOG_PATH"; then
    echo "Kernel boot signature not detected in QEMU log"
    cat "$LOG_PATH" || true
    exit 1
fi

cat <<TABLE | tee "$SUMMARY_PATH"
┌────────────┬───────────────────────────────────────────────┐
│ ✅ Status  │ QEMU boot log captured successfully            │
│ 🕒 Timeout │ $QEMU_TIMEOUT seconds                          │
│ 📜 Log     │ $LOG_PATH                                      │
│ 🚀 Args    │ ${QEMU_ARGS_ARRAY[*]}                          │
└────────────┴───────────────────────────────────────────────┘
TABLE

echo "QEMU log check passed"
echo "📄 QEMU summary saved to $SUMMARY_PATH"
