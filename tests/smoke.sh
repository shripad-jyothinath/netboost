#!/bin/sh
# Smoke tests that do not require a device: help text, version and module metadata.
set -eu

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=../scripts/lib.sh
. "$REPO_ROOT/scripts/lib.sh"

log "bandctl help"
sh "$REPO_ROOT/magisk/tools/bandctl.sh" --help | grep -q 'Profiles:'
sh "$REPO_ROOT/magisk/tools/bandctl.sh" --help | grep -q 'srm-lte'

log "bench help"
sh "$REPO_ROOT/magisk/tools/bench.sh" --help | grep -q 'Usage:'

log "cli help"
sh "$REPO_ROOT/magisk/system/bin/netboost" help | grep -q 'netboost'
sh "$REPO_ROOT/magisk/system/bin/netboost" help | grep -q 'reelmode'

log "cli version"
[ "$(sh "$REPO_ROOT/magisk/system/bin/netboost" version)" = "netboost $VERSION" ]

log "module metadata"
grep -q '^id=netboost$' "$REPO_ROOT/magisk/module.prop"
grep -q "^version=$VERSION$" "$REPO_ROOT/magisk/module.prop"

log "vendored checksum"
EXPECTED=$(awk '{ print $1; exit }' "$REPO_ROOT/vendor/qcom-band-menu.sha256")
verify_sha256 "$REPO_ROOT/third_party/qcom-band-menu/qcom-band-menu" "$EXPECTED"

log "smoke ok"
