# Guide: Turn a XIAO ESP32C6 into a Thread Border Router

This guide takes a Seeed Studio XIAO ESP32C6 from the box to a working Thread Border
Router on your Wi-Fi network, and then connects it to Home Assistant so you can add
Matter-over-Thread devices.

**Time:** about 30 minutes, most of it waiting for the first Docker download.

---

## 1. How it works

A **Thread Border Router** connects a Thread mesh network (the low-power 2.4 GHz
network used by many Matter sensors, plugs and bulbs) to your normal home IP network.

```
 Thread devices  ))) 802.15.4 )))  XIAO ESP32C6  ))) Wi-Fi )))  Router  ── Home Assistant
 (sensors, plugs)                  border router                          phones, etc.
```

The ESP32-C6 has both an 802.15.4 (Thread) radio and Wi-Fi, so a single chip can do
the whole job. The board only needs USB power, so you can put it anywhere in range of
your Wi-Fi.

**Trade-off:** the C6 has one 2.4 GHz RF path, so Wi-Fi and Thread take turns using
it ("coexistence"). That works for a typical home setup, but latency is higher and
throughput lower than with dedicated border routers. If you later need more
performance, see [Alternatives](#9-alternatives).

## 2. What you need

**Hardware**

- Seeed Studio XIAO ESP32C6 (the onboard antenna is enough; the U.FL connector is
  optional)
- A USB-C cable that carries **data** (many cheap cables are charge-only)
- Any USB power adapter for where the board will live afterwards

**Network**

- A Wi-Fi network with a **2.4 GHz** band (the C6 cannot use 5 GHz). Routers that
  combine 2.4 and 5 GHz under one name are fine.

**Software on your computer** (macOS or Linux)

- [Docker](https://docs.docker.com/get-docker/) (builds the firmware, so you don't need
  to install ESP-IDF)
- Python 3 (for `esptool`, the flashing tool; installed automatically)
- Git and OpenSSL (preinstalled on macOS and most Linux distributions)

## 3. Get the project

```sh
git clone https://github.com/RunningCircles42/esp32c6-thread-br.git
cd esp32c6-thread-br
```

## 4. Create your private settings

```sh
scripts/gen-secrets.sh
```

This creates `sdkconfig.secrets` with a **randomly generated Thread network** (network
key, PAN ID, etc.) and placeholders for Wi-Fi. Open it and set your Wi-Fi name and
password:

```sh
open -e sdkconfig.secrets      # macOS (TextEdit)
nano sdkconfig.secrets         # Linux
```

```
CONFIG_EXAMPLE_WIFI_SSID="MyHomeWifi"
CONFIG_EXAMPLE_WIFI_PASSWORD="my wifi password"
```

Keep the straight double quotes. In TextEdit, make sure they don't become curly
quotes (Format → Make Plain Text helps).

> **Keep this file private.** It is git-ignored. Anyone with the Thread network key
> can join and read your Thread network.

Optional settings in the same file:

| Setting | Default | Notes |
|---|---|---|
| `CONFIG_OPENTHREAD_NETWORK_NAME` | `XIAO-Thread` | Shown in Home Assistant and apps |
| `CONFIG_OPENTHREAD_NETWORK_CHANNEL` | `25` | Thread channels are 11–26. 25 sits above Wi-Fi channel 11 and avoids most Wi-Fi overlap. |

## 5. Build the firmware

```sh
scripts/build.sh
```

The first run downloads Espressif's `espressif/idf:v6.0.3` Docker image (several GB)
and the project's dependencies. Later builds take a minute or two. The result is
written to `firmware/build/`.

The build combines three settings files, later ones overriding earlier ones:

1. `firmware/sdkconfig.defaults`: Espressif's example defaults
2. `firmware/sdkconfig.defaults.xiao`: this board's settings (built-in Thread radio,
   Wi-Fi coexistence, automatic start, console on USB)
3. `sdkconfig.secrets`: your Wi-Fi and Thread credentials

## 6. Flash the board

Plug the XIAO into your computer and run:

```sh
scripts/flash.sh
```

The script picks the first `/dev/cu.usbmodem*` (macOS) or `/dev/ttyACM*` (Linux)
port. If you have several boards connected, pass the port explicitly:
`scripts/flash.sh /dev/cu.usbmodem1101`.

**If flashing fails to connect:** put the board into download mode manually: hold
the **B** (BOOT) button, press and release **R** (RESET), release **B**, then run
`scripts/flash.sh` again. Press **R** once after flashing to start the new firmware.

**Linux permission errors:** add yourself to the serial group and log in again:
`sudo usermod -aG dialout $USER` (`uucp` on Arch).

## 7. Check that it works

Open the serial console (exit with **Ctrl+]**):

```sh
scripts/monitor.sh
```

Press **R** on the board to see the boot log from the start. You should see, in order:

1. `XIAO antenna: onboard`
2. Wi-Fi connecting and getting an IPv4 address from your router
3. OpenThread starting, the board becoming Thread **leader**, and the border router
   starting

Then try these commands in the console:

| Command | Expected |
|---|---|
| `ot state` | `leader` (only device in the Thread network so far) |
| `ot channel` | your channel, e.g. `25` |
| `ot networkname` | e.g. `XIAO-Thread` |
| `ot br state` | `running` |
| `ot ipaddr` | several IPv6 addresses |

On first boot, the board creates the Thread network from `sdkconfig.secrets` and
saves it to flash. After that it resumes the same network on every power-up,
including after a power cut.

Now unplug it and plug it into a USB power adapter wherever you want it. See
[Placement tips](#placement-tips).

## 8. Connect it to Home Assistant

Home Assistant uses the **Thread** integration to know about Thread networks and the
**Matter** integration to add Matter devices. To commission Matter-over-Thread devices
onto *this* border router's network, Home Assistant needs its credentials, called the
*active dataset*.

1. **Get the dataset.** Connect the board to your computer, run `scripts/monitor.sh`,
   and enter:
   ```
   ot dataset active -x
   ```
   Copy the long hex string it prints. Treat it like a password: it contains the
   network key.
2. **Add the Thread integration**, if you don't have it: *Settings → Devices &
   services → Add integration → Thread*. Home Assistant may already have discovered the
   border router on your network.
3. **Import the dataset:** open *Settings → Devices & services → Thread → Configure*,
   open the **⋮** menu in the top-right corner, choose **Add dataset from TLV**, and
   paste the hex string.
4. **Make it preferred:** the network appears under *Other networks*. Open its menu and
   choose **Make preferred network**. Home Assistant (and its Companion app) now uses
   this network when commissioning Matter devices.
5. **Sync to your phone.** Commissioning goes through the Home Assistant Companion
   app, which needs the preferred Thread credentials on the phone. On Android, use the
   **Sync Thread credentials** option in the app's Companion app troubleshooting
   settings. On iOS, the app offers to save the credentials when you add a Matter
   device.
6. **Add a device:** *Settings → Devices & services → Add device → Add Matter device*
   in the Companion app, then scan the device's Matter QR code.

Apple Home and Google Home run their own Thread border routers (HomePod, Apple TV,
Nest Hub). They keep using their own Thread network unless you specifically share
credentials with them, so this board doesn't interfere with them.

### Placement tips

- Put it somewhere central with a decent Wi-Fi signal. Thread is a **mesh**:
  mains-powered Thread devices (plugs, bulbs) relay traffic, so the border router only
  needs to reach one of them, not every device.
- Keep the board away from metal enclosures, behind-the-TV spots and microwave ovens.
- A short USB extension cable lets you move the board away from noisy USB 3 ports
  and chargers.

## 9. Alternatives

If coexistence causes problems (slow responses, devices dropping off under heavy Wi-Fi
use), there are two common upgrades:

- **Radio for a host computer (RCP):** flash the C6 with Espressif's `ot_rcp` example
  instead and plug it into the Home Assistant machine, which then runs the
  *OpenThread Border Router* add-on. The C6 then uses its whole radio for Thread.
- **Two-chip border router:** Espressif's recommended production setup (for example
  ESP32-S3 + ESP32-H2), with a separate chip for each radio.

## 10. Maintenance

**Rebuild after changing settings:** run `scripts/build.sh` and `scripts/flash.sh`
again. The build script removes the generated `firmware/sdkconfig` each time, so
changes to the settings files always apply.

**Change Wi-Fi:** edit `sdkconfig.secrets`, rebuild and flash. The Thread network is
kept.

**Change or reset the Thread network:** the Thread network is stored in the board's
flash and survives reflashing. To replace it, erase the flash before flashing:

```sh
.venv/bin/esptool --chip esp32c6 erase-flash
scripts/flash.sh
```

Every device on the old Thread network has to be added again afterwards.

## 11. Troubleshooting

| Symptom | Fix |
|---|---|
| No `/dev/cu.usbmodem*` or `/dev/ttyACM*` appears | Use a data-capable USB-C cable; try download mode (hold B, tap R, release B). |
| `Missing .../sdkconfig.secrets` during build | Run `scripts/gen-secrets.sh` first. |
| Console shows nothing | Press **R**, since early boot messages appear before you connect. Check that no other program has the port open. |
| Wi-Fi never connects | Check the name and password (case-sensitive, straight quotes) and that the network has a 2.4 GHz band. Rebuild and reflash after edits. |
| `ot state` stays `detached` or `disabled` | Check the boot log for errors; erase flash and reflash to start fresh. |
| Home Assistant can't add Matter-over-Thread devices | Make sure this network is the **preferred** network (step 8.4) and the phone has the credentials (step 8.5). The Home Assistant host must accept IPv6 router advertisements from the border router. |
| Devices respond slowly or drop off | Coexistence limit: try a different Thread channel, or move to an RCP or two-chip setup ([Alternatives](#9-alternatives)). |
