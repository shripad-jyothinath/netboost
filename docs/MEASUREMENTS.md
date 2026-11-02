# Measurements

## Method

- Device: Motorola Edge 70 Fusion (`marvel`), Snapdragon SM7635, Android 17,
  Magisk 31.1.
- Network: Jio India, NR SA, n78. RSRP ranged from −105 to −108 dBm and
  SS-SINR from 11 to 19 dB during the session.
- Data interface: `rmnet_data3` (IPv6 plus 464XLAT/CLAT, MTU 1400).
- Downloads: 668 MB object on Google's CDN, sampled with a hard timeout.
- Throughput is reported two ways: application bytes (`curl`) and the
  `rmnet_data3` rx-byte delta. The two agreed within a few percent.
- Latency: 10 ICMP echoes to `1.1.1.1`, idle and while the link was loaded.
- Each profile was applied, allowed to settle for ~10 s, then measured.
- The cell was shared and fluctuated by roughly 40 % between runs a minute
  apart. Treat the numbers as ranges, not a benchmark score.

## Results

| Profile | Single stream | 4 streams | Loaded ping (max) |
|---|---|---|---|
| Stock (all bands, SA/NSA) | 178 Mbps | 132 Mbps | 437 ms |
| SA only, all NR bands | 132 Mbps | 146 Mbps | 202 ms |
| n78 only, SA | 133 Mbps | 114 Mbps | 192 ms |
| **n28 + n78, SA** | **155–218 Mbps** | **177–237 Mbps** | **145–367 ms** |
| LTE B3/B5/B40 + n28/n78 | 99 Mbps | 104 Mbps | 253 ms |

The best observed single-stream result was 218 Mbps; the same profile
measured 155 Mbps a few minutes later. The stock profile measured 178 Mbps
once and 132–150 Mbps on other passes. The useful signal is that n28+n78
consistently improved **parallel** throughput (177–237 Mbps vs 132 Mbps on
stock) and usually reduced loaded latency.

## IPv4 vs IPv6

25 MB single-stream download from Cloudflare:

| Path | Throughput | TCP connect |
|---|---|---|
| IPv6 (native) | 130 Mbps | 23 ms |
| IPv4 (464XLAT + NAT64) | 65 Mbps | 105 ms |

Jio is IPv6-native. IPv4 is translated on the device (CLAT) and again in the
network (NAT64), which roughly halves throughput in this sample. Do not
disable IPv6; there is no device-side fix that makes the IPv4 path as fast.

## What did not help

- **BBR.** The kernel is built with `CONFIG_TCP_CONG_ADVANCED` disabled and
  exposes only `reno` and `cubic`. More importantly, download congestion
  control runs on the server. The upstream BBR module author's own A/B test
  found no attributable download change.
- **TCP receive buffers.** Android writes `tcp_rmem = 2/6/16 MB` and
  `tcp_wmem = 512 KB/2/8 MB` when the mobile PDN comes up. At 450 Mbps and
  60 ms RTT the BDP is about 3.4 MB, so 16 MB is not the ceiling.
- **Restricting LTE bands.** Removing B1/B2/B8/B28/B38/B41/B42 reduced
  throughput to ~99 Mbps. The modem appears to use some of those carriers for
  CA or fallback in this market. Leave LTE at the hardware defaults.
- **Generic "TCP optimizer" Magisk modules.** They cannot add radio capacity
  and their fixed presets conflict with Android's per-network buffer setup.

## Why latency under load matters

The loaded ping peaked at 437 ms on the stock profile even when throughput
was 178 Mbps. Reels and other short-form video need a few Mbps and a stable
RTT, not a 200 Mbps peak. The n28+n78 profile generally lowered the loaded
latency, which is the more relevant improvement for interactive use.

## Limitations

- One device, one carrier, one cell, one evening. The absolute numbers will
  not transfer to another site.
- The CDN endpoint is a Google object; a different CDN may show a different
  ceiling.
- No thermal soak or multi-hour stability run was performed.
- No band-locked comparison at a second location was possible.
- `srm`/`srm-lte` were added for the SRM Kattankulathur campus but were not
  measured there. The 2019 SRM 4G study is the only public campus data point;
  current 5G coverage may differ.
- RS-SINR and RSRP come from `dumpsys telephony.registry`; the modem does not
  report NR bandwidth or per-carrier CA details on this build.
