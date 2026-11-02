#!/system/bin/sh
# Boot service: apply the persistent profile and conservative TCP tuning.
MODDIR=${0%/*}
# shellcheck source=tools/common.sh
. "$MODDIR/tools/common.sh"

nb_ensure_dir "$NB_HOME"
exec >> "$NB_HOME/service.log" 2>&1

printf '\n[%s] netboost service start\n' "$(date)"

i=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ "$i" -lt 120 ]; do
  sleep 2
  i=$((i + 1))
done
sleep 5

# Upload-side tuning only. Android sets tcp_rmem/tcp_wmem per mobile network.
sysctl -w net.ipv4.tcp_limit_output_bytes=2097152 2>/dev/null || true
sysctl -w net.ipv4.tcp_notsent_lowat=262144 2>/dev/null || true

# Keep the mobile PDN alive while the Wi-Fi client is associated.
settings put global mobile_data_always_on 1 2>/dev/null || true

PROFILE=$(nb_read_profile)
if [ -n "$PROFILE" ] && [ "$PROFILE" != "none" ]; then
  i=0
  while [ "$i" -lt 6 ]; do
    printf '[%s] applying profile %s (attempt %s)\n' "$(date)" "$PROFILE" "$i"
    if sh "$MODDIR/tools/bandctl.sh" "$PROFILE"; then
      break
    fi
    sleep 10
    i=$((i + 1))
  done
fi

printf '[%s] netboost service done\n' "$(date)"
