# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.1] - 2026-11-03

### Fixed

- CLI module detection now requires `tools/common.sh`, so running the staged
  1.2.x CLI does not try to source an older module's incomplete tools
  directory.

## [1.2.0] - 2026-11-03

### Added

- `netboost wifi-tune on|off|status`: disables scan-always and the vendor
  Wi-Fi power-save setting, with a stock restore path.
- `docs/WIFI.md`: SRMIST 5 GHz link measurements, campus throughput cap,
  Google-vs-Cloudflare peering, blocked DoT/ICMP, and the measured effect of
  the tuning.

## [1.1.0] - 2026-11-02

### Added

- `netboost reelmode on|off|status`: enables Android Data Saver, whitelists
  the media apps, and restores the previous background policy on exit.
- `srm` profile: NR-SA n28 only, SA, for weak indoor signal at SRM
  Kattankulathur and similar concrete buildings.
- `srm-lte` profile: LTE B3/B5/B28/B40 only, as the weak-signal fallback.
- Weak-signal hint in `netboost status` when RSRP is below −110 dBm or SINR
  is below 5 dB.
- Documentation for the SRM KTR case, including the campus carrier study and
  the second-SIM limitation.

## [1.0.0] - 2026-11-02

### Added

- Reversible QMI band profiles for Qualcomm modems: `reset`, `n78n28`,
  `n78`, `saonly`, and `lte`.
- `netboost` CLI for status, profile switching, benchmarks, TCP tuning and
  hotspot-aware Wi-Fi state.
- Sustained single-stream and four-stream download benchmark with
  interface-counter cross-checking and loaded-latency measurement.
- Magisk module with a boot service, profile retry, and a clean uninstall
  path that restores stock sysctls, settings and band masks.
- Vendored `qcom-band-menu` at a pinned revision with a SHA-256 lock and
  matching GPL-3.0 source.
- Device-free lint and smoke tests, plus a GitHub Actions workflow that
  verifies the built module zip.

### Notes

- No NV writes, no boot image changes, no kernel modules.
- `tcp_rmem`/`tcp_wmem` are intentionally left to Android's per-network
  `TcpBufferSizes`.
- Measured on a Motorola Edge 70 Fusion on Jio 5G in Chennai; absolute
  throughput is cell-dependent (see `docs/MEASUREMENTS.md`).

[1.2.1]: https://github.com/shripad-jyothinath/netboost/releases/tag/v1.2.1
[1.2.0]: https://github.com/shripad-jyothinath/netboost/releases/tag/v1.2.0
[1.1.0]: https://github.com/shripad-jyothinath/netboost/releases/tag/v1.1.0
[1.0.0]: https://github.com/shripad-jyothinath/netboost/releases/tag/v1.0.0
