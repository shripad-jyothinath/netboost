# netboost

**Reversible, measurement-driven network tuning for rooted Qualcomm Android devices.**

[![CI](https://github.com/shripad-jyothinath/netboost/actions/workflows/ci.yml/badge.svg)](https://github.com/shripad-jyothinath/netboost/actions/workflows/ci.yml)
[![License: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue.svg)](LICENSE)
[![Platform: Android 11+](https://img.shields.io/badge/platform-Android%2011%2B-green.svg)](#requirements)
[![Root: Magisk 26+](https://img.shields.io/badge/root-Magisk%2026%2B-orange.svg)](#requirements)
[![Shell: POSIX](https://img.shields.io/badge/shell-POSIX-informational.svg)](#development)

`netboost` applies temporary NR/LTE band profiles through Qualcomm's QMI NAS
interface, then measures what actually changed. It never writes modem NV,
never touches the boot image, and never loads a kernel module. Reboot or
`netboost profile reset` returns the device to stock.

Built and measured on a Motorola Edge 70 Fusion (`marvel`, Snapdragon SM7635)
on Jio 5G in Chennai. The profile engine is carrier-agnostic; the default
profile targets Jio's n28 + n78 deployment.

## Table of contents

- [Why](#why)
- [What it does](#what-it-does)
- [Measured results](#measured-results)
- [How it works](#how-it-works)
- [Requirements](#requirements)
- [Install](#install)
- [Usage](#usage)
- [Profiles](#profiles)
- [Weak indoor signal (SRM KTR)](#weak-indoor-signal-srm-ktr)
- [Safety](#safety)
- [Troubleshooting](#troubleshooting)
- [Development](#development)
- [Project layout](#project-layout)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Why

A modern 5G phone can show five bars and still stall on a reel. The usual
causes are not "missing TCP tweaks":

- the modem camps on a low-capacity carrier (n28) instead of a wide one (n78);
- it ping-pongs between n78, n28 and LTE, resetting throughput each time;
- latency under load spikes into the hundreds of milliseconds;
- IPv4 traffic takes a translated 464XLAT path that is slower than native IPv6;
- a weak Wi-Fi client is preferred over a perfectly good 5G link.

`netboost` gives you one command to inspect those conditions and one command
to apply a known-good band profile, with a benchmark that measures the result
instead of guessing.

## What it does

| Capability | Detail |
|---|---|
| Reversible band profiles | QMI `Set System Selection Preference` over QRTR; not NV |
| NR SA control | SA-only mode, separate NR-SA and NR-NSA masks |
| Reel mode | Data Saver + media whitelist; stops game/Play Store background updates |
| Latency-aware benchmark | Single/4-stream throughput plus idle and loaded ICMP latency |
| Safe boot service | Applies the saved profile with retries, logs every attempt |
| Clean uninstall | Restores stock sysctls, settings and hardware band masks |
| No kernel changes | No boot image, no `.ko`, no vermagic/CFI risk |

## Measured results

Test cell: Jio 5G, n78, RSRP −105 to −108 dBm, SS-SINR 11–19 dB, 0 % ICMP loss.
The cell fluctuated by roughly 40 % between runs a minute apart, so these are
observed ranges, not a controlled benchmark.

| Profile | Single stream | 4 streams | Loaded ping (max) |
|---|---|---|---|
| Stock (all bands, SA/NSA) | 178 Mbps | 132 Mbps | 437 ms |
| SA only, all NR bands | 132 Mbps | 146 Mbps | 202 ms |
| n78 only, SA | 133 Mbps | 114 Mbps | 192 ms |
| **n28 + n78, SA** | **155–218 Mbps** | **177–237 Mbps** | **145–367 ms** |
| LTE B3/B5/B40 + n28/n78 | 99 Mbps | 104 Mbps | 253 ms |

**IPv4 vs IPv6** (25 MB single stream): native IPv6 **130 Mbps**, IPv4 via
464XLAT/CLAT **65 Mbps**. Jio is IPv6-native; disabling IPv6 makes things
worse, not better.

The n28+n78 profile consistently improved multi-stream throughput and usually
reduced latency under load. It does not create radio capacity: on a congested
cell, no device-side change can guarantee a number. See
[`docs/MEASUREMENTS.md`](docs/MEASUREMENTS.md) for the full method and caveats.

## How it works

```text
netboost CLI -> bandctl.sh -> qcom-band-menu
                                    |
                                    | AF_QIPCRTR / QMI NAS
                                    v
                              modem (QRTR)
```

`bandctl.sh` maps a named profile to a short command stream and drives the
vendored QMI client. The client sends `Set System Selection Preference`
(0x0033) with RAT, LTE, NR-SA/NR-NSA masks and the NR operating mode. A modem
restart or reboot discards the forcing.

The boot service waits for Android, applies upload-side TCP tuning and
`mobile_data_always_on`, then retries the saved profile while the modem
registers. Details and the TLV layout are in
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Requirements

- Qualcomm Snapdragon device with a working QMI NAS service (tested on SM7635)
- Android 11 or newer
- Magisk 26+ (or KernelSU/APatch with Magisk module support)
- Root shell capable of the `magisk` SELinux domain
- `curl` and `ping` on the device (present on AOSP and most OEM builds)
- For building: `zip` (or `7z`/`python3`), `curl`, POSIX `sh`

## Install

### Magisk

```sh
make build
adb push build/netboost-1.1.0.zip /data/local/tmp/netboost.zip
adb shell su -c "magisk --install-module /data/local/tmp/netboost.zip"
adb reboot
```

Or:

```sh
make install
# or install and reboot in one step:
./scripts/install.sh --reboot
```

After reboot:

```sh
su -c netboost status
```

### From source

```sh
git clone https://github.com/shripad-jyothinath/netboost.git
cd netboost
make test
make build
```

`make build` verifies the vendored binary's SHA-256, lays out the Magisk
payload, and produces `build/netboost-<version>.zip`.

## Usage

```sh
su -c netboost status
su -c netboost bench 5
su -c netboost profile n78n28
su -c netboost profile reset
su -c netboost reelmode on
su -c netboost reelmode off
su -c netboost tune on
su -c netboost wifi off
su -c netboost hotspot
```

`netboost wifi off` disables only the Wi-Fi **client**. The SoftAP is managed
by Android's tethering service and is never touched by this project.

`netboost bench` downloads from a configurable CDN endpoint and reports both
the application throughput and the `rmnet` interface counter, plus idle and
loaded latency. Override the defaults:

```sh
NETBOOST_BENCH_URL=https://example.com/large.bin \
NETBOOST_IFACE=rmnet_data2 \
su -c netboost bench 8
```

`netboost reelmode on` enables Android Data Saver and whitelists the media
apps (Instagram, YouTube, WhatsApp, Telegram, Chrome, Spotify) so game and
Play Store updates stop competing for the radio. Foreground video is
unaffected. `netboost reelmode off` restores the previous background policy.

## Profiles

| Profile | RAT | NR-SA mask | NR mode | Use |
|---|---|---|---|---|
| `reset` | GSM/WCDMA/LTE/NR | hardware default | SA/NSA | stock |
| `n78n28` | GSM/WCDMA/LTE/NR | n28 + n78 | SA | recommended |
| `n78` | GSM/WCDMA/LTE/NR | n78 | SA | lower latency |
| `saonly` | GSM/WCDMA/LTE/NR | hardware default | SA | experimental |
| `srm` | GSM/WCDMA/LTE/NR | n28 | SA | SRM KTR / indoor coverage |
| `srm-lte` | LTE | unchanged | unchanged | weak-signal LTE fallback |
| `lte` | LTE | unchanged | unchanged | fallback testing |

The profile is persisted in `/data/adb/netboost/band_profile` and re-applied
by the boot service. `profile reset` writes `none`, so the service leaves the
modem alone on the next boot.

## Weak indoor signal (SRM KTR)

n78 (3.5 GHz) carries Jio's capacity but dies indoors; n28 (700 MHz) and LTE
B5 (850 MHz) are the coverage layers. A 2019 SRM Kattankulathur campus study
across University Block, Java Food Court, Tech Park, Valliammai Gate and the
hospital found **Airtel the most consistent carrier and Jio the weakest**
(Jio had no coverage at Valliammai Gate). If classmates get data in class,
they are likely on Airtel, or their phones have fallen back to LTE low-band.

Try these in order and keep the one that works:

```sh
su -c netboost profile srm       # NR-SA n28 only (700 MHz)
su -c netboost profile srm-lte   # LTE B3/B5/B28/B40 only
su -c netboost profile reset     # back to normal when you leave campus
```

`netboost status` prints a hint when RSRP is below −110 dBm or SINR below
5 dB. n28 is slower (often 1–5 Mbps in weak spots) but penetrates concrete;
n78 may be faster only near a window. If the phone shows 5G but no data,
`srm-lte` is the closest match to what the "everyone else has data" phones
are doing.

Root cannot change your carrier. The phone has **SIM 2 empty** and supports
eSIM; a second Airtel SIM/eSIM is the only way to truly match an Airtel
classmate. Campus Wi-Fi or Wi-Fi calling is the other alternative.

See the [SRM 4G study](https://www.ijitee.org/wp-content/uploads/papers/v8i8s/H10100688S19.pdf).

## Safety

- Band changes are **runtime QMI forcings**, not NV writes. Reboot restores
  the hardware defaults.
- `profile reset` is the one-command rollback.
- Removing the module restores stock sysctls, `mobile_data_always_on`, and the
  band masks.
- No boot image, kernel, or `.ko` changes.
- The QMI client must run in the Magisk SELinux domain; `shell` is denied
  `qipcrtr_socket` on the tested platform. This is expected.

Read [`docs/SAFETY.md`](docs/SAFETY.md) before applying a profile on a device
you cannot recover.

## Troubleshooting

Start with [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md). The most
common cases:

- `netboost: not found` — the module is staged in
  `/data/adb/modules_update/netboost`; reboot or run the staged copy.
- `profile was not applied` — the modem rejected the QMI setter; run
  `profile reset` and attach `/data/adb/netboost/service.log` to a bug report.
- 5G icon but slow — check RSRP/SINR, IPv6 vs IPv4, and whether a weak Wi-Fi
  client is associated.

## Development

```sh
make lint      # sh -n, shellcheck, CRLF check
make test      # lint + device-free smoke tests
make build     # reproducible Magisk zip
make fetch     # refresh the vendored QMI tool from its pinned revision
```

The CI workflow runs `make test` and `make build` on Ubuntu, then verifies the
zip layout. Device-side scripts must remain POSIX `sh` (mksh on Android) and
pass ShellCheck with `-s sh`.

## Project layout

```text
magisk/               Magisk module payload
  system/bin/netboost CLI
  tools/              bandctl, bench, shared helpers
  service.sh          boot service
scripts/              fetch, build and install tooling
tests/                lint and smoke tests
third_party/          vendored qcom-band-menu (GPL-3.0) and source
vendor/               pinned checksum
docs/                 architecture, measurements, safety, troubleshooting
```

## Contributing

Issues and pull requests are welcome. Please read
[`CONTRIBUTING.md`](CONTRIBUTING.md) first.

## License

GPL-3.0-or-later. See [`LICENSE`](LICENSE).

The vendored `third_party/qcom-band-menu` is GPL-3.0; its source is included
for license compliance. See
[`third_party/qcom-band-menu/NOTICE.md`](third_party/qcom-band-menu/NOTICE.md).

## Acknowledgements

- [Fronsipswu/qcom-band-menu](https://github.com/Fronsipswu/qcom-band-menu) —
  the QMI NAS client and its documented TLV layout.
- [iliyian/android-gki-bbr-kmod](https://github.com/iliyian/android-gki-bbr-kmod) —
  the BBR-on-GKI experiment and its download-vs-upload benchmark.
- [Anurag Bhatia — Jio 5G IPv6-only](https://anuragbhatia.com/post/2023/02/jio-5g-ipv6-only/) —
  background on 464XLAT in Jio's network.
