# shellcheck shell=sh
# Shared helpers for repository-side scripts.

set -eu

REPO_ROOT=${REPO_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}
VERSION=$(tr -d ' \r\n' < "$REPO_ROOT/VERSION" 2>/dev/null || true)
export VERSION

log() {
  printf '%s\n' "$*"
}

warn() {
  printf 'warning: %s\n' "$*" >&2
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{ print $1 }'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{ print $1 }'
  else
    die "no SHA-256 tool found (sha256sum or shasum)"
  fi
}

verify_sha256() {
  file=$1
  expected=$2
  actual=$(sha256_of "$file")
  [ "$actual" = "$expected" ] || die "checksum mismatch for $file"
}
