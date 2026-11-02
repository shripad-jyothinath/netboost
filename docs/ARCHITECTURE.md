# Architecture

`netboost` is two things: a small shell control plane that runs on the device,
and a vendored QMI client that talks to the modem. Nothing is linked into the
Android framework and nothing is written to modem NV.

## Radio control path

```text
adb shell / Magisk service
        |
        v
  netboost CLI  (magisk/system/bin/netboost)
        |
        v
  bandctl.sh    (magisk/tools/bandctl.sh)
        |
        v
  qcom-band-menu (vendored, ARM64)
        |
        |  AF_QIPCRTR / SOCK_DGRAM
        v
  QRTR control service (node 1, port 0xFFFFFFFE)
        |
        |  NEW_LOOKUP for QMI NAS (service 0x03, version 1, instance 0)
        v
  QMI NAS service
        |
        v
  modem
```

`qcom-band-menu` is driven over stdin with a tiny command language
(`sim 1`, `sa 28,78`, `mode sa`, `refresh`, `exit`). `bandctl.sh` maps a
named profile to those commands, validates the modem's response, and prints
the resulting selection.

## QMI messages

The client uses two NAS messages:

| Message | ID | Purpose |
|---|---|---|
| Get System Selection Preference | `0x0034` | Read current RAT, LTE and NR masks |
| Set System Selection Preference | `0x0033` | Apply a temporary forcing |

Relevant TLVs:

| TLV | Meaning |
|---|---|
| `0x11` | RAT preference (GSM / WCDMA / LTE / NR) |
| `0x15` | LTE B1-B64 bitmap |
| `0x17` | Change duration |
| `0x2B` | Combined NR band bitmap |
| `0x2C` / `0x2D` | NR-SA / NR-NSA report masks |
| `0x2E` | NR operating mode: `0` = SA+NSA, `1` = NSA, `2` = SA |
| `0x2F` / `0x30` | NR-SA / NR-NSA set masks |

`Set System Selection Preference` is a runtime forcing. It is **not** an NV
write: a modem restart or a reboot restores the hardware defaults. This is
the core safety property of the project.

## SELinux

The process that opens `AF_QIPCRTR` must be in the Magisk domain
(`u:r:magisk:s0`). The `shell` domain is denied
`create ... tclass=qipcrtr_socket` on the tested build, which is why every
entry point is executed through `su -c` or by the Magisk boot service.

## Profiles

| Name | RAT | NR-SA mask | NR mode | Intent |
|---|---|---|---|---|
| `reset` | GSM/WCDMA/LTE/NR | hardware default | SA/NSA | stock |
| `n78n28` | GSM/WCDMA/LTE/NR | n28 + n78 | SA | recommended |
| `n78` | GSM/WCDMA/LTE/NR | n78 | SA | lower latency |
| `saonly` | GSM/WCDMA/LTE/NR | hardware default | SA | experimental |
| `srm` | GSM/WCDMA/LTE/NR | n28 | SA | weak indoor signal (SRM KTR) |
| `srm-lte` | LTE | unchanged | unchanged | weak-signal LTE fallback |
| `lte` | LTE | unchanged | unchanged | fallback testing |

Jio's 5G deployments in the tested region use n78 (3.5 GHz, capacity) and
n28 (700 MHz, coverage). `n78n28` keeps both carriers eligible for NR CA
while preventing the n78 → n28 → LTE reselection cycle. `srm` intentionally
drops n78: indoors, 700 MHz penetrates concrete where 3.5 GHz does not.

## Reel mode

`netboost reelmode on` flips Android's global Data Saver policy
(`cmd netpolicy set restrict-background true`) and adds the media UIDs to the
restrict-background whitelist. Foreground playback is unaffected; background
game/Play Store downloads stop competing for the radio scheduler. The previous
policy and whitelist are saved under `/data/adb/netboost/` and restored by
`reelmode off`. This is an Android setting, not a modem or kernel change, and
it does not affect tethered clients.

## Boot flow

1. Magisk mounts the module and runs `service.sh`.
2. The service waits for `sys.boot_completed`, then five more seconds.
3. Upload-side sysctls are applied (failures are non-fatal).
4. `mobile_data_always_on` is set to `1`.
5. If `/data/adb/netboost/band_profile` contains a profile name, `bandctl.sh`
   is retried up to six times while the modem registers.
6. Everything is appended to `/data/adb/netboost/service.log`.

## Repository layout

```text
magisk/                 payload copied into the module zip
  system/bin/netboost   user-facing CLI
  tools/common.sh       shared device-side helpers
  tools/bandctl.sh      profile -> QMI commands
  tools/bench.sh        sustained throughput + loaded latency
  service.sh            boot service
  customize.sh          Magisk installer hook
  uninstall.sh          restore stock state
scripts/                repository-side build and install tools
tests/                  lint and device-free smoke tests
third_party/            vendored qcom-band-menu (GPL-3.0) + source
vendor/                 pinned checksum
docs/                   this documentation
```

## Design decisions

- **SA-only** matches Jio's standalone deployment and avoids an LTE anchor.
- **n28 + n78** is the smallest mask that preserves both coverage and NR CA.
- **No BBR**: the tested kernel has `CONFIG_TCP_CONG_ADVANCED` disabled. BBR
  also only affects the sender, and download congestion control runs on the
  server, so a kernel module would not raise download throughput.
- **No `tcp_rmem` override**: Android's per-network `TcpBufferSizes` already
  sets 2/6/16 MB receive and 512 KB/2/8 MB send buffers on the mobile PDN.
  A boot script would be overwritten by netd on the next network change.
- **Upload-only TCP tuning**: `tcp_limit_output_bytes` and
  `tcp_notsent_lowat` are the only limits that are not reset by the framework,
  and they do not distort download behaviour.
- **No NV writes, no boot image changes, no kernel modules.**
