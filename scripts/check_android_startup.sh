#!/usr/bin/env bash
set -euo pipefail
apk_path="${1:?Provide the release APK path}"
app_package=com.scorex.app.scorex
mkdir -p startup-report
adb install -r "$apk_path"
adb logcat -c
adb shell am start -W -n "$app_package/.MainActivity" > startup-report/launch.txt 2>&1 || true
for attempt in 1 2 3; do
  sleep 10
  adb logcat -d -v threadtime > startup-report/logcat.txt
  adb shell screencap -p /sdcard/scorex-startup.png
  adb pull /sdcard/scorex-startup.png startup-report/screen.png > /dev/null
  if ! adb shell pidof "$app_package" > startup-report/pid.txt; then
    cat startup-report/launch.txt
    rg -n -A 45 -B 8 'FATAL EXCEPTION|Fatal signal|AndroidRuntime|Could not|flutter.*ERROR|Dart Error' startup-report/logcat.txt || true
    echo 'ScoreX exited during startup.'
    exit 1
  fi
done
cat startup-report/launch.txt
echo 'ScoreX remained running for 30 seconds.'
