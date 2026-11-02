# Safety

## Three guarantees

1. **No NV writes.** Band changes use QMI `Set System Selection Preference`,
   a runtime forcing. A reboot or modem restart restores the hardware
   defaults. The tool never writes NV items.
2. **No boot image changes.** The project is a Magisk module. Removing the
   module and rebooting returns the device to its previous state.
3. **No kernel modules.** Nothing is loaded into the kernel, so there is no
   vermagic, CFI or ABI risk.

## What is changed

| Change | Scope | Revert |
|---|---|---|
| NR-SA mask and NR mode | Runtime QMI forcing | `netboost profile reset` or reboot |
| `tcp_limit_output_bytes` | Runtime sysctl | `netboost tune off` or reboot |
| `tcp_notsent_lowat` | Runtime sysctl | `netboost tune off` or reboot |
| `mobile_data_always_on` | Android global setting | Module uninstall sets it back to `0` |
| Data Saver + whitelist | Android netpolicy | `netboost reelmode off` |

The module does not touch `tcp_rmem` or `tcp_wmem`; Android sets those per
mobile network and would overwrite a boot-time value anyway.

## Risks

- **Temporary loss of 5G.** If the selected NR bands are not available, the
  modem falls back to LTE (the RAT mask still includes LTE). In a location
  with no LTE either, data would be unavailable until you run
  `netboost profile reset` or reboot.
- **Modem rejection.** If the modem rejects a profile, `bandctl.sh` exits
  non-zero and the previous selection remains. It does not silently apply a
  partial mask.
- **SELinux.** The QMI client must run in the Magisk domain. Running it from
  an unprivileged `shell` context fails with a `qipcrtr_socket` denial; this
  is expected and not a bug.
- **Data usage.** The benchmark downloads several hundred megabytes per run.
  It is not run automatically.
- **Carrier terms.** Band selection and tethering are subject to your
  carrier's terms and local radio regulations. Use responsibly.

## Revert everything

```sh
su -c netboost profile reset
su -c netboost reelmode off
su -c netboost tune off
```

Then remove the module in Magisk and reboot. `uninstall.sh` restores the
stock sysctls, sets `mobile_data_always_on=0`, applies the hardware band
masks, and deletes `/data/adb/netboost`.

## If something goes wrong

1. Run `su -c netboost profile reset` and reboot.
2. If the CLI is unavailable, disable or remove the module in the Magisk app
   and reboot.
3. If you cannot boot, boot to safe mode / recovery and remove
   `/data/adb/modules/netboost`. The boot image and kernel are untouched, so
   recovery from a bad module is the standard Magisk procedure.
