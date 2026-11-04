#!/usr/bin/env bash
# Create sdkconfig.secrets with random Thread credentials and Wi-Fi placeholders.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ -e sdkconfig.secrets ]]; then
  echo "sdkconfig.secrets already exists; refusing to overwrite." >&2
  exit 1
fi
umask 077
hex() { openssl rand -hex "$1"; }
cat > sdkconfig.secrets <<CFG
# Private build settings — do not commit or share.
# --- Wi-Fi (2.4 GHz only; the ESP32-C6 cannot see 5 GHz networks) ---
CONFIG_EXAMPLE_WIFI_SSID="YOUR_WIFI_NAME"
CONFIG_EXAMPLE_WIFI_PASSWORD="YOUR_WIFI_PASSWORD"

# --- Thread network credentials (randomly generated $(date +%F)) ---
CONFIG_OPENTHREAD_NETWORK_NAME="XIAO-Thread"
CONFIG_OPENTHREAD_NETWORK_CHANNEL=25
CONFIG_OPENTHREAD_NETWORK_PANID=0x$(hex 2)
CONFIG_OPENTHREAD_NETWORK_EXTPANID="$(hex 8)"
CONFIG_OPENTHREAD_NETWORK_MASTERKEY="$(hex 16)"
CONFIG_OPENTHREAD_NETWORK_PSKC="$(hex 16)"
CONFIG_OPENTHREAD_MESH_LOCAL_PREFIX="fd$(hex 1):$(hex 2):$(hex 2):$(hex 2)::/64"
CFG
echo "Wrote sdkconfig.secrets — now set your Wi-Fi name and password in it."
