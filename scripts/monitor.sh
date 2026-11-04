#!/usr/bin/env bash
# Open the serial console (logs + "ot" CLI). Exit with Ctrl+].
set -euo pipefail
cd "$(dirname "$0")/.."
PORT="${1:-$(ls /dev/cu.usbmodem* 2>/dev/null | head -1)}"
exec .venv/bin/python -m serial.tools.miniterm --raw --eol LF "$PORT" 115200
