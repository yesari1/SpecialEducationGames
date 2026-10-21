#!/usr/bin/env bash
# Builds the signed Play bundle and refuses to hand it over untested.
#
#   bash tools/build_release.sh            # build + checks + Pixel_9a smoke launch
#   SKIP_DEVICE=1 bash tools/build_release.sh   # build + static checks only
#
# Why: vc16-vc19 shipped without io.flutter.plugins.GeneratedPluginRegistrant
# (the file was deleted and `--no-pub` did not regenerate it), so no plugin
# registered and the app closed on launch. Never build release with --no-pub
# and never delete the registrant by hand: `flutter build` regenerates it
# without dev-only plugins (integration_test).
set -euo pipefail
cd "$(dirname "$0")/.."
export MSYS_NO_PATHCONV=1

version=$(grep '^version:' pubspec.yaml | awk '{print $2}')
name=${version%+*}
code=${version#*+}
out="GooglePlayBuild/ozel-egitim-oyunlari-${name}-vc${code}.aab"

flutter build appbundle --release
aab=build/app/outputs/bundle/release/app-release.aab

# Counts dex mentions (no grep -q: with pipefail its early exit fails unzip).
has_registrant() {
  [ "$(unzip -p "$1" "$2" | grep -a -c 'io/flutter/plugins/GeneratedPluginRegistrant')" -gt 0 ]
}

# 1) Plugin registrant must be inside the bundle.
if ! has_registrant "$aab" 'base/dex/*.dex'; then
  echo "FAIL: GeneratedPluginRegistrant missing from $aab" >&2
  exit 1
fi
# 2) Signed with the upload key (not debug).
if [ "$(keytool -printcert -jarfile "$aab" | grep -c 'CN=Android Debug')" -gt 0 ]; then
  echo "FAIL: bundle is debug-signed" >&2
  exit 1
fi

# 3) Smoke launch of the same release code on Pixel_9a.
if [ "${SKIP_DEVICE:-0}" != 1 ]; then
  flutter build apk --release
  apk=build/app/outputs/flutter-apk/app-release.apk
  has_registrant "$apk" '*.dex' \
    || { echo "FAIL: registrant missing from release APK" >&2; exit 1; }
  adb="$LOCALAPPDATA/Android/Sdk/platform-tools/adb.exe"
  serial=""
  for d in $("$adb" devices | awk 'NR>1 && $2=="device" {print $1}'); do
    [ "$("$adb" -s "$d" emu avd name 2>/dev/null | head -1 | tr -d '\r')" = Pixel_9a ] && serial=$d
  done
  [ -n "$serial" ] || { echo "FAIL: Pixel_9a emulator is not running" >&2; exit 1; }
  pkg=com.YeS.OzelEgitimOyunlari
  # A debug-signed install blocks the upload-signed one.
  "$adb" -s "$serial" install -r "$apk" >/dev/null 2>&1 || {
    "$adb" -s "$serial" uninstall "$pkg" >/dev/null
    "$adb" -s "$serial" install "$apk" >/dev/null
  }
  "$adb" -s "$serial" shell am force-stop "$pkg"
  "$adb" -s "$serial" logcat -c
  "$adb" -s "$serial" shell am start -W -n "$pkg/com.YeS.special_education_games.MainActivity" >/dev/null
  sleep 10
  log=$("$adb" -s "$serial" logcat -d)
  if [ -z "$("$adb" -s "$serial" shell pidof "$pkg" | tr -d '\r')" ] ||
     [ "$(echo "$log" | grep -c -E "FATAL EXCEPTION|GeneratedPluginRegistrant|E/flutter")" -gt 0 ]; then
    echo "$log" | grep -E "FATAL|AndroidRuntime|GeneratedPlugin|E/flutter" | head -40 >&2
    echo "FAIL: release build did not stay up on Pixel_9a" >&2
    exit 1
  fi
  echo "OK: release build launched on $serial and stayed up"
fi

cp "$aab" "$out"
echo "OK: $out"
