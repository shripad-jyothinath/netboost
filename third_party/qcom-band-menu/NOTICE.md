# qcom-band-menu

Vendored copy of the QMI band-control utility used by `netboost` to apply
temporary NR/LTE band profiles on Qualcomm modems.

| | |
|---|---|
| Upstream | <https://github.com/Fronsipswu/qcom-band-menu> |
| Revision | `a0d28b4dba9dbc98fdd36aa1b781b9f720f8c341` |
| License | GNU General Public License v3.0 (`LICENSE`) |
| Binary | `qcom-band-menu` — ARM64 Android ELF, 34,400 bytes |
| Source | `qcom-band-menu.c` — corresponding upstream source |

## Checksum

```text
a332a0b838e2970f54452b133f1d7c2506dce79eb86fc5a542abcc63fc4b483b  qcom-band-menu
```

The canonical checksum lives in [`vendor/qcom-band-menu.sha256`](../../vendor/qcom-band-menu.sha256).

## How netboost uses it

`netboost` executes the binary as a separate process and talks to it over
stdin/stdout. No code is linked into netboost, so netboost's own shell code
remains under the repository license while this directory stays GPL-3.0.

The binary is vendored so that `make build` produces a byte-reproducible
Magisk zip without network access. To refresh it:

```sh
scripts/fetch-band-tool.sh
```

That script downloads the pinned revision, verifies the SHA-256 above, and
replaces the binary only if the checksum matches.

## Security notes

The tool opens an `AF_QIPCRTR` datagram socket and sends QMI NAS
`Set System Selection Preference` requests. It does not write NV items, so
band changes do not survive a modem restart or reboot. It must run as root
(`u:r:magisk:s0` under Magisk); the `shell` SELinux domain is not permitted
to create `qipcrtr_socket` sockets on this device.
