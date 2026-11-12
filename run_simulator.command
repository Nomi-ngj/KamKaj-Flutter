#!/bin/zsh -l
# Boots an iOS Simulator and runs KamKaj Pro on it.
cd "$(dirname "$0")"
export PATH="$HOME/flutter/bin:$HOME/development/flutter/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
command -v flutter >/dev/null || { echo "flutter not found on PATH"; exit 1; }
open -a Simulator
UDID=$(xcrun simctl list devices booted | grep -Eo '[0-9A-F-]{36}' | head -1)
if [ -z "$UDID" ]; then
  UDID=$(xcrun simctl list devices available | grep -E 'iPhone' | grep -Eo '[0-9A-F-]{36}' | head -1)
  xcrun simctl boot "$UDID"
fi
echo "Using simulator $UDID"
flutter clean
flutter precache --ios
flutter pub get
flutter run -v -d "$UDID" 2>&1 | tee run_simulator.log
