#!/system/bin/sh
# Restore stock values when the module is removed.
MODDIR=${0%/*}
# shellcheck source=tools/common.sh
. "$MODDIR/tools/common.sh"

sysctl -w net.ipv4.tcp_limit_output_bytes=506072 2>/dev/null || true
sysctl -w net.ipv4.tcp_notsent_lowat=16384 2>/dev/null || true
settings put global mobile_data_always_on 0 2>/dev/null || true

if [ -x "$MODDIR/tools/bandctl.sh" ]; then
  sh "$MODDIR/tools/bandctl.sh" reset >/dev/null 2>&1 || true
fi

rm -rf "$NB_HOME"
