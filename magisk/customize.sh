#!/system/bin/sh
# Magisk installer hook.
# shellcheck disable=SC2154

set_perm_recursive "$MODPATH" 0 0 0755 0644
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755
set_perm "$MODPATH/system/bin/netboost" 0 0 0755
set_perm "$MODPATH/tools/bandctl.sh" 0 0 0755
set_perm "$MODPATH/tools/bench.sh" 0 0 0755

if [ -f "$MODPATH/tools/qcom-band-menu" ]; then
  set_perm "$MODPATH/tools/qcom-band-menu" 0 0 0755
else
  ui_print "! qcom-band-menu missing; band profiles will be unavailable"
fi

mkdir -p /data/adb/netboost
ui_print "- netboost installed"
ui_print "- control: su -c netboost status"
