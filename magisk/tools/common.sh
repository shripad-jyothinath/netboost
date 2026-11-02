# shellcheck shell=sh
# Shared helpers for netboost device-side scripts.
# Source this file; it intentionally does not enable set -e.

NB_VERSION=${NB_VERSION:-1.1.0}
NB_HOME=${NETBOOST_HOME:-/data/adb/netboost}
NB_WORK=${NETBOOST_WORK:-/data/local/tmp/netdiag}
export NB_VERSION NB_HOME NB_WORK

nb_log() {
  printf '%s\n' "$*"
}

nb_warn() {
  printf 'netboost: warning: %s\n' "$*" >&2
}

nb_die() {
  printf 'netboost: error: %s\n' "$*" >&2
  exit 1
}

nb_require_root() {
  [ "$(id -u)" = "0" ] || nb_die "must run as root (try: su -c ...)"
}

nb_require_cmd() {
  command -v "$1" >/dev/null 2>&1 || nb_die "required command not found: $1"
}

nb_ensure_dir() {
  [ -d "$1" ] || mkdir -p "$1" || nb_die "cannot create directory: $1"
}

nb_is_uint() {
  case "${1:-}" in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

nb_read_profile() {
  if [ -r "$NB_HOME/band_profile" ]; then
    tr -d '\r\n' < "$NB_HOME/band_profile"
  else
    printf 'none'
  fi
}

nb_write_profile() {
  nb_ensure_dir "$NB_HOME"
  printf '%s\n' "$1" > "$NB_HOME/band_profile"
}
