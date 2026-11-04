# XIAO ESP32C6 Thread Border Router

A standalone, single-chip [Thread](https://openthread.io/) Border Router running on a
[Seeed Studio XIAO ESP32C6](https://wiki.seeedstudio.com/xiao_esp32c6_getting_started/).
It joins your Wi-Fi network and forms its own Thread network on power-up, so it can be
placed anywhere with USB power.

**→ Step-by-step instructions: [docs/GUIDE.md](docs/GUIDE.md)** (build, flash, verify, and
connect to Home Assistant / Matter).

Based on Espressif's [`ot_br` example](https://github.com/espressif/esp-idf/tree/v6.0.3/examples/openthread/ot_br)
from ESP-IDF v6.0.3 (original README in [`firmware/README.espressif.md`](firmware/README.espressif.md)).

## Changes from the upstream example

| What | Where |
|---|---|
| Uses the C6's built-in 802.15.4 radio instead of an external RCP chip, with Wi-Fi/Thread software coexistence | `firmware/sdkconfig.defaults.xiao` |
| Auto-starts: connects to Wi-Fi and forms/resumes the Thread network on boot (IDF v6.0's `ot_br` no longer starts Thread by itself, so `app_main` calls `ot_network_auto_start()`) | `firmware/sdkconfig.defaults.xiao`, `firmware/main/esp_ot_br.c` |
| Logs and the `ot` CLI on the XIAO's USB-C port (USB-Serial/JTAG) | `firmware/sdkconfig.defaults.xiao` |
| Drives the XIAO RF switch (GPIO3 low = enabled, GPIO14 low = onboard antenna) | `firmware/main/esp_ot_br.c` |
| Wi-Fi and Thread credentials read from a git-ignored `sdkconfig.secrets` | `firmware/CMakeLists.txt` |

### Limitation

The ESP32-C6 has a single 2.4 GHz RF path, so Wi-Fi and Thread take turns using it.
Espressif notes this has a significant performance impact and recommends a two-chip
design (e.g. ESP32-S3 + ESP32-H2) for production. This build is fine for a home network
with a modest number of devices, but expect higher latency and occasional packet loss
under load.

## Requirements

- Docker (builds use the official `espressif/idf:v6.0.3` image; no local ESP-IDF install)
- Python 3 (for `esptool`, installed into `.venv/` automatically by `scripts/flash.sh`)
- OpenSSL (for generating credentials)

## Usage

```sh
# 1. Create private credentials (random Thread network key, Wi-Fi placeholders)
scripts/gen-secrets.sh
open -e sdkconfig.secrets        # set your 2.4 GHz Wi-Fi name and password

# 2. Build in Docker
scripts/build.sh

# 3. Flash over USB (auto-detects /dev/cu.usbmodem*, or pass the port)
scripts/flash.sh

# 4. Watch logs / use the OpenThread CLI (exit with Ctrl+])
scripts/monitor.sh
```

Useful CLI commands once it is running:

```
ot state                 # should become "leader"
ot dataset active -x     # active operational dataset (hex TLVs) – keep private
ot br state              # border routing state
ot ipaddr
```

### Notes

- `sdkconfig.secrets` is git-ignored and must never be committed: the Thread network key
  gives full access to the Thread network.
- `scripts/build.sh` deletes the generated `firmware/sdkconfig` before each build so that
  changes to the `sdkconfig.*` files always apply.
- The Thread network is created on first boot and stored in flash. Changing the Thread
  credentials and re-flashing does **not** change an existing network; erase flash first
  (`.venv/bin/esptool --chip esp32c6 erase-flash`).
- To use an external U.FL antenna, set `XIAO_USE_EXTERNAL_ANT` to `1` in
  `firmware/main/esp_ot_br.c`.
