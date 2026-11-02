# Troubleshooting

## `netboost: not found`

The module is installed but not active yet. After
`magisk --install-module`, Magisk stages files in
`/data/adb/modules_update/netboost`. Either reboot, or run the staged copy:

```sh
su -c sh /data/adb/modules_update/netboost/system/bin/netboost status
```

## `Permission denied` reading `/data/adb`

Some `su -c` invocations with a compound command run in the `shell` SELinux
domain. Put the command in a script file and run the script:

```sh
adb push setup.sh /data/local/tmp/setup.sh
adb shell 'su -c "sh /data/local/tmp/setup.sh"'
```

The `netboost` CLI itself sources `/data/adb/modules/netboost/tools/common.sh`
and is intended to be started with `su -c netboost ...`.

## `NAS discovery failed`

`qcom-band-menu` could not open `AF_QIPCRTR` or did not receive a QRTR lookup
response. Check:

```sh
su -c 'id; cat /proc/self/attr/current'
```

The context must be `u:r:magisk:s0`. The `shell` domain is denied
`qipcrtr_socket` creation on this platform. Do not add a permissive SELinux
rule unless you understand the impact.

## `band tool not executable`

The built module includes `tools/qcom-band-menu`. If you copied files
manually, restore the executable bit:

```sh
su -c 'chmod 0755 /data/adb/modules/netboost/tools/qcom-band-menu'
```

## `profile was not applied`

The modem rejected the QMI setter. The previous selection is still active.
Collect the raw output from `/data/adb/netboost/service.log`, then:

```sh
su -c netboost profile reset
```

## No data after a profile change

```sh
su -c netboost profile reset
```

or reboot. `reset` restores the hardware band masks and the full RAT mask.
If the CLI is unavailable, disable the module in Magisk and reboot.

## 5G icon but slow / reels stall

1. Check the radio metrics: `su -c netboost status`. RSRP below about
   −110 dBm or SINR below about 10 dB usually means the cell is the limit.
2. Check whether a Wi-Fi client is associated. A weak 2.4 GHz AP can be
   selected over a perfectly good 5G link. `netboost wifi off` disables only
   the client; it does **not** stop the hotspot.
3. Test IPv6 explicitly. On Jio, IPv4 goes through 464XLAT and can be about
   half the native IPv6 throughput.
4. Run `netboost bench 5` and compare idle versus loaded latency. A large gap
   is bufferbloat/queueing in the radio network, not a device fault.

## SRM KTR / weak indoor signal

n78 is capacity, n28 (700 MHz) and LTE B5 (850 MHz) are coverage. Inside a
concrete classroom the phone can show 5G and still have no usable data
because it is camped on a distant n78 cell. Try, in order:

```sh
su -c netboost profile srm       # NR-SA n28 only
su -c netboost profile srm-lte   # LTE B3/B5/B28/B40 only
su -c netboost profile reset     # restore when you leave
```

`netboost status` prints a hint when RSRP is below −110 dBm or SINR below
5 dB. n28 is slower (often 1–5 Mbps in weak spots) but penetrates concrete.
If `srm` has no data, `srm-lte` is the closest match to what classmates'
phones are doing when they fall back to LTE.

If classmates get data and you do not, check their SIM. A 2019 SRM
Kattankulathur study found Airtel the most consistent carrier and Jio the
weakest. Root cannot change your carrier; a second Airtel SIM/eSIM (SIM 2 is
empty on this phone) or campus Wi-Fi is the only true match.

## Reel mode / Data Saver

`netboost reelmode on` enables Android Data Saver and whitelists the media
apps so background game/Play Store updates stop competing for the radio.
Verify:

```sh
su -c netboost reelmode status
su -c cmd netpolicy get restrict-background
```

`reelmode off` restores the previous background policy. Data Saver persists
across reboots; the module does not change it on boot. Tethered clients are
not affected.

## Hotspot turned off

`svc wifi disable` only disables the Wi-Fi **client**. The SoftAP is managed
separately. Check it with:

```sh
su -c netboost hotspot
su -c cmd wifi status
```

If the SoftAP is down, enable it from Settings → Hotspot & tethering. The
module never changes hotspot state.

## Benchmark cannot reach the network

- Confirm the URL is reachable: `curl -I https://dl.google.com/`.
- Override the source: `NETBOOST_BENCH_URL=... su -c netboost bench 5`.
- Confirm the interface name:
  `ip -o addr show | grep rmnet`. Override with
  `NETBOOST_IFACE=rmnet_data2`.

## Logs

| File | Content |
|---|---|
| `/data/adb/netboost/service.log` | boot service output and band retries |
| `/data/adb/netboost/last-apply.log` | per-attempt band profile output (older builds) |
| `/data/local/tmp/netdiag/bench-*.log` | benchmark results |

## Uninstall

Remove the module in Magisk and reboot. `uninstall.sh` restores the stock
sysctls, `mobile_data_always_on=0`, the hardware band masks, and deletes
`/data/adb/netboost`.
