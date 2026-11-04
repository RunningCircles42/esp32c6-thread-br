#!/usr/bin/env bash
# Open the serial console (logs + "ot" CLI). Exit with Ctrl+].
set -euo pipefail
cd "$(dirname "$0")/.."
PORT="${1:-$(ls /dev/cu.usbmodem* /dev/ttyACM* 2>/dev/null | head -1 || true)}"
[[ -n "$PORT" ]] || { echo "No serial port found; pass one explicitly." >&2; exit 1; }
[[ -x .venv/bin/python ]] || { python3 -m venv .venv && .venv/bin/pip install -q esptool; }
exec .venv/bin/python -m serial.tools.miniterm --raw --eol LF "$PORT" 115200
