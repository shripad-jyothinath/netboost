# Wi-Fi

## Tested link (SRMIST, Kattankulathur)

- SSID `SRMIST`, BSSID `54:f0:b1:3d:3a:30`, **5180 MHz (5 GHz channel 36)**,
  802.11ax, WPA2-Enterprise, IPv4 only (`10.9.16.186`).
- RSSI −63 to −66 dBm, link **432/272 Mbps before tuning, 480/272 Mbps after**.
- The scan showed the other SRMIST 5 GHz BSSIDs at −77 and −83 dBm, and the
  2.4 GHz BSSIDs at −71/−72 dBm. The connected AP was already the strongest.

## Actual throughput

Clean runs, before the campus/Cloudflare rate limiter kicked in:

| Test | Result |
|---|---|
| Cloudflare 25 MB, single stream | **55.4 Mbps** (6.9 MB/s) |
| Cloudflare 2 × 10 MB | **78.5 Mbps** aggregate |
| Cloudflare 25 MB, before tuning | 40.5 Mbps |
| Google NDK 10 MB (range request) | 4.5 Mbps (18.7 s) |

After roughly 100 MB of transfers in a few minutes, later runs dropped to
10–34 Mbps with HTTP 200 responses. That is a rate limit, not a link failure;
the first clean runs are the useful numbers.

**Google peering is the outlier.** Cloudflare served 40–55 Mbps while Google
served 4.5 Mbps over the same link. Prefer apps/CDNs that peer well with the
campus; this is not controllable from the phone.

## Latency

ICMP is blocked on SRMIST (100 % loss to the gateway and 1.1.1.1), so latency
must be measured with TCP/TTFB:

| Host | Before tuning | After tuning |
|---|---|---|
| `i.instagram.com` | 879 ms TTFB | **371 ms TTFB** |
| `www.google.com` | 907 ms TTFB | 1044 ms TTFB |
| `speed.cloudflare.com` | 255 ms TTFB | 381 ms TTFB |

DoT (TCP 853) is blocked to 1.1.1.1 and 8.8.8.8, so Android Private DNS
cannot be used on this network. DNS lookups are 50–75 ms via the campus
resolver.

## Tuning applied

`netboost wifi-tune on`:

- `settings put global wifi_scan_always_enabled 0`
- `cmd wifi set-scan-always-available disabled`
- `settings put global wifi_power_save 0` (stock value is `120`)

`netboost wifi-tune off` restores `1`, `enabled`, and `120`.

No band, BSSID, or channel change was made. The phone was already on the
strongest 5 GHz SRMIST AP. Disabling scan-always and power save raised the
link rate from 432 to 480 Mbps and cut Instagram TTFB by more than half.

## What cannot be fixed from the phone

- The campus network caps real throughput at roughly **50–80 Mbps per
  client**; the 480 Mbps PHY link is not the limit.
- Google peering is ~4.5 Mbps; other CDNs are 10× faster.
- The AP is 80 MHz Wi-Fi 6 with a 600 Mbps maximum; there is no 6 GHz or
  160 MHz to enable.
- Root cannot raise the campus cap. A wired connection, a different AP/time,
  or another carrier is the only way past it.

## Commands

```sh
su -c netboost wifi-tune on
su -c netboost wifi-tune status
su -c netboost wifi-tune off
```

`wifi-tune status` prints the two settings and the current `WifiInfo` line
(band, RSSI, link speed, standard).
