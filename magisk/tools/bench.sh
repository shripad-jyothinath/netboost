#!/system/bin/sh
# bench.sh - sustained download and latency-under-load benchmark.
#
# Throughput is measured two ways:
#   * curl bytes / curl time  (application view)
#   * rmnet interface rx delta (radio view, survives partial transfers)
set -eu

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

DURATION=5
PARALLEL=4
IFACE=${NETBOOST_IFACE:-rmnet_data3}
URL=${NETBOOST_BENCH_URL:-https://dl.google.com/android/repository/android-ndk-r26d-linux.zip}
WORK=${NETBOOST_WORK:-/data/local/tmp/netdiag}
TMP=$WORK/.bench-tmp

usage() {
  cat <<'EOF'
Usage: bench.sh [seconds]

Runs a sustained single-stream and 4-stream download, then measures ICMP
latency while the link is loaded. Defaults to 5 seconds per phase.

Environment:
  NETBOOST_IFACE       rmnet interface to sample (default: rmnet_data3)
  NETBOOST_BENCH_URL   large file URL (default: Google NDK zip on dl.google.com)
  NETBOOST_WORK        output directory (default: /data/local/tmp/netdiag)
EOF
}

iface_rx() {
  cat "/sys/class/net/$IFACE/statistics/rx_bytes" 2>/dev/null || printf '0\n'
}

mbps() {
  awk -v bytes="$1" -v secs="$2" 'BEGIN {
    if (secs > 0) printf "%.2f", bytes * 8 / 1000000 / secs;
    else printf "0.00";
  }'
}

wait_net() {
  i=0
  while [ "$i" -lt 30 ]; do
    if curl -fsS -r 0-1023 -o /dev/null --max-time 3 "$URL" 2>/dev/null; then
      return 0
    fi
    sleep 2
    i=$((i+1))
  done
  return 1
}

radio_state() {
  if ! command -v dumpsys >/dev/null 2>&1; then
    return 0
  fi
  dumpsys telephony.registry 2>/dev/null \
    | grep -m1 'mServiceState=' \
    | tr ',' '\n' \
    | grep -E 'mOperatorAlphaLong|getRilDataRadioTechnology|mDataRegState' \
    | head -n 3 || true
  dumpsys telephony.registry 2>/dev/null \
    | grep -m1 'mSignalStrength=' \
    | tr ',' '\n' \
    | grep -E 'ssRsrp|ssRsrq|ssSinr' || true
}

ping_phase() {
  printf '%s_ping\n' "$1"
  ping -c 10 -i 0.2 -W 2 1.1.1.1 2>&1 | tail -n 2 || true
}

measure_single() {
  before=$(iface_rx)
  curl -sS -o /dev/null --max-time "$DURATION" \
    -w '%{size_download} %{time_total}\n' "$URL" > "$TMP/single" 2>/dev/null || true
  after=$(iface_rx)
  bytes=$(awk 'NR == 1 { print $1 }' "$TMP/single")
  secs=$(awk 'NR == 1 { print $2 }' "$TMP/single")
  printf 'single_stream_mbps=%s  iface_mbps=%s\n' \
    "$(mbps "$bytes" "$secs")" \
    "$(mbps "$((after - before))" "$DURATION")"
}

measure_parallel() {
  before=$(iface_rx)
  i=1
  while [ "$i" -le "$PARALLEL" ]; do
    curl -sS -o /dev/null --max-time "$DURATION" \
      -w '%{size_download} %{time_total}\n' "$URL" > "$TMP/par$i" 2>/dev/null &
    i=$((i+1))
  done
  wait
  after=$(iface_rx)
  total=$(awk '{ sum += $1 } END { print sum + 0 }' "$TMP"/par*)
  longest=$(awk '{ if ($2 > max) max = $2 } END { print max + 0 }' "$TMP"/par*)
  printf 'parallel_streams=%s  parallel_mbps=%s  iface_mbps=%s\n' \
    "$PARALLEL" \
    "$(mbps "$total" "$longest")" \
    "$(mbps "$((after - before))" "$DURATION")"
}

run_benchmark() {
  printf 'netboost benchmark  %s\n' "$(date)"
  printf 'iface=%s  url=%s  duration=%ss\n\n' "$IFACE" "$URL" "$DURATION"

  printf '%s\n' '--- radio ---'
  radio_state

  printf '%s\n' '--- waiting for network ---'
  if ! wait_net; then
    nb_die "network did not come up"
  fi
  printf 'ok\n\n'

  ping_phase idle

  printf '%s\n' '--- single stream ---'
  measure_single

  printf '%s\n' '--- parallel streams ---'
  measure_parallel

  printf '%s\n' '--- loaded latency ---'
  curl -sS -o /dev/null --max-time $((DURATION + 10)) "$URL" >/dev/null 2>&1 &
  sleep 1
  ping_phase loaded
  wait || true
}

main() {
  case "${1:-}" in
    -h|--help)
      usage
      exit 0
      ;;
  esac

  if [ "$#" -gt 0 ]; then
    DURATION=$1
  fi

  nb_is_uint "$DURATION" || nb_die "duration must be an integer"
  if [ "$DURATION" -lt 1 ] || [ "$DURATION" -gt 60 ]; then
    nb_die "duration must be between 1 and 60 seconds"
  fi

  nb_require_root
  nb_require_cmd curl
  nb_require_cmd ping
  nb_ensure_dir "$WORK"
  rm -rf "$TMP"
  mkdir -p "$TMP"
  # shellcheck disable=SC2064
  trap "rm -rf '$TMP'" EXIT HUP INT TERM

  LOG=$WORK/bench-$(date +%Y%m%d-%H%M%S).log
  if ! run_benchmark > "$LOG" 2>&1; then
    cat "$LOG" >&2
    nb_die "benchmark failed"
  fi
  cat "$LOG"
  printf '\nlog: %s\n' "$LOG"
}

main "$@"
