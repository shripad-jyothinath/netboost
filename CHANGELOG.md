# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/)
and the project uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[1.0.0]: https://github.com/shripad-jyothinath/netboost/releases/tag/v1.0.0
