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
