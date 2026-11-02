#!/bin/sh
# Install the built module over adb.
set -eu

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=lib.sh
. "$REPO_ROOT/scripts/lib.sh"

REBOOT=0
case "${1:-}" in
  --reboot) REBOOT=1 ;;
  "") ;;
  *) die "usage: scripts/install.sh [--reboot]" ;;
esac

require_cmd adb
ZIP=$REPO_ROOT/build/netboost-$VERSION.zip
[ -f "$ZIP" ] || die "module not built; run: make build"

adb push "$ZIP" /data/local/tmp/netboost.zip
adb shell "su -c 'magisk --install-module /data/local/tmp/netboost.zip'"

log "module installed"
if [ "$REBOOT" = "1" ]; then
  log "rebooting"
  adb reboot
else
  log "reboot to activate, or run the tools from /data/adb/modules_update/netboost"
fi
