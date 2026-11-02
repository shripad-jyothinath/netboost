#!/system/bin/sh
# bandctl.sh - apply a reversible QMI system-selection profile.
#
# The profile is written with QMI NAS "Set System Selection Preference"
# over QRTR. It is not an NV write: a modem restart or reboot restores the
# hardware defaults.
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

TOOL=${NETBOOST_BAND_TOOL:-$SCRIPT_DIR/qcom-band-menu}
WORK=${NETBOOST_WORK:-/data/local/tmp/netdiag}
CMDS=$WORK/band-commands.txt

usage() {
  cat <<'EOF'
Usage: bandctl.sh <profile>

Profiles:
  reset     hardware defaults (all bands, SA/NSA)
  n78n28    NR-SA n28+n78, SA only (recommended)
  n78       NR-SA n78 only, SA only (lower latency)
  saonly    all NR-SA bands, SA only
  lte       LTE B3/B5/B40 only (fallback testing)
  show      print the current selection

The change is temporary: reboot or "profile reset" restores the modem.
EOF
}

profile_commands() {
  case "$1" in
    reset)
      printf 'reset\nrat gsm,wcdma,lte,nr\n'
      ;;
    n78n28)
      printf 'reset\nrat gsm,wcdma,lte,nr\nsa 28,78\nmode sa\n'
      ;;
    n78)
      printf 'reset\nrat gsm,wcdma,lte,nr\nsa 78\nmode sa\n'
      ;;
    saonly)
      printf 'reset\nrat gsm,wcdma,lte,nr\nmode sa\n'
      ;;
    lte)
      printf 'reset\nrat gsm,wcdma,lte,nr\nrat lte\nlte 3,5,40\n'
      ;;
    show)
      printf 'refresh\n'
      ;;
    *)
      return 1
      ;;
  esac
}

main() {
  if [ "$#" -ne 1 ]; then
    usage >&2
    exit 2
  fi

  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
  esac

  BODY=$(profile_commands "$1") || {
    usage >&2
    exit 2
  }

  nb_require_root
  [ -x "$TOOL" ] || nb_die "band tool not executable: $TOOL"
  nb_ensure_dir "$WORK"

  {
    printf 'sim 1\n'
    printf '%s\n' "$BODY"
    printf 'exit\n'
  } > "$CMDS"

  if ! OUT=$("$TOOL" < "$CMDS" 2>&1); then
    printf '%s\n' "$OUT" >&2
    nb_die "band tool failed"
  fi

  case "$OUT" in
    *"Command accepted."*|*"State refreshed."*|*"All band masks restored."*) ;;
    *)
      printf '%s\n' "$OUT" >&2
      nb_die "profile was not applied"
      ;;
  esac

  printf '%s\n' "$OUT" \
    | grep -E '^(RAT|GSM|WCDMA|LTE|NR-NSA|NR-SA|NR MODE):' \
    | tail -n 7
}

main "$@"
