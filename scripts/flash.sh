#!/usr/bin/env bash
# Flash the built firmware from the host (Docker on macOS can't reach USB).
# Usage: scripts/flash.sh [PORT]   (default: first /dev/cu.usbmodem* or /dev/ttyACM*)
set -euo pipefail
cd "$(dirname "$0")/.."
PORT="${1:-$(ls /dev/cu.usbmodem* /dev/ttyACM* 2>/dev/null | head -1 || true)}"
[[ -n "$PORT" ]] || { echo "No /dev/cu.usbmodem* or /dev/ttyACM* port found; pass one explicitly." >&2; exit 1; }
[[ -x .venv/bin/esptool ]] || { python3 -m venv .venv && .venv/bin/pip install -q esptool; }
cd firmware/build
exec ../../.venv/bin/esptool --chip esp32c6 -p "$PORT" -b 460800 write-flash @flash_args
