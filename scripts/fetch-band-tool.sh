#!/bin/sh
# Fetch the pinned qcom-band-menu revision and verify its checksum.
set -eu

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=lib.sh
. "$REPO_ROOT/scripts/lib.sh"

REVISION=a0d28b4dba9dbc98fdd36aa1b781b9f720f8c341
URL="https://raw.githubusercontent.com/Fronsipswu/qcom-band-menu/$REVISION/qcom-band-menu"
DEST=$REPO_ROOT/third_party/qcom-band-menu/qcom-band-menu
LOCK=$REPO_ROOT/vendor/qcom-band-menu.sha256

require_cmd curl
[ -f "$LOCK" ] || die "missing checksum lock: $LOCK"
EXPECTED=$(awk '{ print $1; exit }' "$LOCK")

TMP=$(mktemp) || die "cannot create a temporary file"
trap 'rm -f "$TMP"' EXIT HUP INT TERM

log "fetching $URL"
curl -fsSL "$URL" -o "$TMP" || die "download failed"
verify_sha256 "$TMP" "$EXPECTED"

cp "$TMP" "$DEST"
chmod 0755 "$DEST"
log "installed $DEST"
