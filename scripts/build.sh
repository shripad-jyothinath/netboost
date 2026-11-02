#!/bin/sh
# Build the installable Magisk module zip.
set -eu

REPO_ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source=lib.sh
. "$REPO_ROOT/scripts/lib.sh"

require_cmd cp
require_cmd mkdir
require_cmd sed

[ -f "$REPO_ROOT/magisk/module.prop" ] || die "missing magisk/module.prop"
[ -f "$REPO_ROOT/third_party/qcom-band-menu/qcom-band-menu" ] \
  || die "missing vendored tool; run: scripts/fetch-band-tool.sh"

MODULE_VERSION=$(sed -n 's/^version=//p' "$REPO_ROOT/magisk/module.prop")
[ "$MODULE_VERSION" = "$VERSION" ] \
  || die "VERSION ($VERSION) does not match module.prop ($MODULE_VERSION)"

EXPECTED=$(awk '{ print $1; exit }' "$REPO_ROOT/vendor/qcom-band-menu.sha256")
verify_sha256 "$REPO_ROOT/third_party/qcom-band-menu/qcom-band-menu" "$EXPECTED"

BUILD=$REPO_ROOT/build
MODULE=$BUILD/module
ZIP=$BUILD/netboost-$VERSION.zip

rm -rf "$MODULE" "$ZIP"
mkdir -p "$MODULE"
cp -R "$REPO_ROOT/magisk/." "$MODULE/"
cp "$REPO_ROOT/third_party/qcom-band-menu/qcom-band-menu" "$MODULE/tools/qcom-band-menu"

chmod 0755 \
  "$MODULE/service.sh" \
  "$MODULE/uninstall.sh" \
  "$MODULE/system/bin/netboost" \
  "$MODULE/tools/bandctl.sh" \
  "$MODULE/tools/bench.sh" \
  "$MODULE/tools/qcom-band-menu"

if command -v zip >/dev/null 2>&1; then
  (
    cd "$MODULE"
    find . -type f | sed 's|^\./||' | sort | zip -q -X "$ZIP" -@
  )
elif command -v 7z >/dev/null 2>&1; then
  (
    cd "$MODULE"
    7z a -tzip -mx=9 "$ZIP" . >/dev/null
  )
elif command -v python3 >/dev/null 2>&1; then
  python3 - "$MODULE" "$ZIP" <<'PY'
import os
import sys
import zipfile

src, dst = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED) as archive:
    for root, _, files in os.walk(src):
        for name in sorted(files):
            path = os.path.join(root, name)
            rel = os.path.relpath(path, src).replace(os.sep, "/")
            archive.write(path, rel)
PY
else
  die "need zip or python3 to build the module"
fi

[ -f "$ZIP" ] || die "build did not produce $ZIP"

if command -v unzip >/dev/null 2>&1; then
  unzip -l "$ZIP" | grep -q 'module.prop' \
    || die "module.prop is not at the zip root"
fi

log "built $ZIP"
log "sha256 $(sha256_of "$ZIP")"
