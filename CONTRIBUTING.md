# Contributing

Thanks for taking the time to improve `netboost`.

## Reporting a bug

Include:

- device model, SoC, Android version and build;
- root implementation and version (Magisk/KernelSU/APatch);
- carrier, MCC/MNC, and whether the SIM is in the slot the tool targeted;
- the output of `su -c netboost status`;
- relevant lines from `/data/adb/netboost/service.log`;
- the exact command that failed and its exit code.

Do **not** include IMEI, serial numbers, SIM identifiers, public IP addresses
or full modem logs. Redact them before attaching.

## Development setup

```sh
git clone https://github.com/shripad-jyothinath/netboost.git
cd netboost
make test
make build
```

You need POSIX `sh`, `shellcheck`, and `zip` (or `7z`/`python3`). Installing on
a device additionally needs `adb` and a rooted phone.

## Code style

- Device-side scripts run under Android's `mksh` as `/system/bin/sh`. Use POSIX
  `sh`; no bash arrays, `[[ ]]`, process substitution or `local`.
- Keep the device dependency set small: `curl`, `ping`, `toybox` applets and
  the vendored QMI binary. Do not require Python on the phone.
- Start scripts with `set -eu` unless they are sourced libraries.
- Quote expansions, prefer `printf`, and fail closed on invalid input.
- Put shared helpers in `magisk/tools/common.sh`; do not duplicate them.
- Never add NV writes, boot image changes, kernel modules, or silent
  fallbacks that mask a modem error.
- New device-side scripts must pass `make lint` (ShellCheck `-s sh`).

## Commit messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```text
feat(band): add n41 profile
fix(bench): handle a missing rmnet interface
docs: clarify the SELinux requirement
test: cover an unknown profile
build: pin the QMI tool checksum
```

Keep the subject imperative and under 72 characters. Explain the why in the
body when the change is not obvious.

## Pull requests

Before opening a PR:

- [ ] `make test` passes.
- [ ] `make build` produces a zip with `module.prop` at its root.
- [ ] New behaviour is covered by a smoke test or documented.
- [ ] The change remains reversible (profile reset or reboot).
- [ ] Documentation is updated when the CLI or a profile changes.

## Safety review

Changes that touch modem control get extra scrutiny. State:

- which QMI message and TLVs are used;
- whether the operation is a runtime forcing or an NV write;
- how the change is reverted;
- what happens if the modem rejects it.

## License

By contributing you agree that your changes are licensed under
GPL-3.0-or-later, matching the rest of the project.
