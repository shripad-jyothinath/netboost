#!/bin/sh
# Static checks: POSIX shell syntax, shellcheck (when available), line endings.
set -eu

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=../scripts/lib.sh
. "$REPO_ROOT/scripts/lib.sh"

FAIL=0

shell_files() {
  find "$REPO_ROOT/magisk" "$REPO_ROOT/scripts" "$REPO_ROOT/tests" \
    -type f -name '*.sh' -print | sort
}

log "syntax check"
# shellcheck disable=SC2046
for file in $(shell_files); do
  if ! sh -n "$file"; then
    warn "syntax error: $file"
    FAIL=1
  fi
done
if ! sh -n "$REPO_ROOT/magisk/system/bin/netboost"; then
  warn "syntax error: magisk/system/bin/netboost"
  FAIL=1
fi

if command -v shellcheck >/dev/null 2>&1; then
  log "shellcheck"
  # SC1091: device scripts source files from paths only known on-device.
  # Run from each file's directory so the static source= directives resolve.
  shellcheck_file() {
    file=$1
    dir=$(dirname "$file")
    base=$(basename "$file")
    (cd "$dir" && shellcheck -s sh -x -e SC1091 "$base")
  }
  # shellcheck disable=SC2046
  for file in $(shell_files); do
    shellcheck_file "$file" || FAIL=1
  done
  shellcheck_file "$REPO_ROOT/magisk/system/bin/netboost" || FAIL=1
else
  warn "shellcheck not installed; skipping"
fi

log "line endings"
CR=$(printf '\r')
if grep -rl "$CR" "$REPO_ROOT/magisk" "$REPO_ROOT/scripts" "$REPO_ROOT/tests" \
  >/dev/null 2>&1; then
  warn "CRLF line endings found"
  FAIL=1
fi

[ "$FAIL" -eq 0 ] || die "lint failed"
log "lint ok"
