#!/usr/bin/env bash
# Build the firmware inside Espressif's official ESP-IDF container.
# Usage: scripts/build.sh [idf.py args...]   (default: build)
set -euo pipefail
cd "$(dirname "$0")/.."
IDF_IMAGE="${IDF_IMAGE:-espressif/idf:v6.0.3}"
# The sdkconfig.* defaults only apply when no generated sdkconfig exists.
# Remove it so edits to the defaults/secrets files always take effect.
rm -f firmware/sdkconfig firmware/sdkconfig.old
exec docker run --rm -e IDF_TARGET=esp32c6 -v "$PWD":/project -w /project/firmware "$IDF_IMAGE" \
  idf.py "${@:-build}"
