#!/usr/bin/env bash
# One-time setup: generates the android/ and ios/ platform folders with
# `flutter create` (existing lib/ and test/ files are left untouched) and
# wires Android release signing to android/key.properties.
#
# Usage (from the project root):  ./tool/setup_platforms.sh
set -euo pipefail

cd "$(dirname "$0")/.."

ORG="com.kamkaj"
NAME="kamkaj_pro"

echo "▶ Generating platform folders…"
flutter create --org "$ORG" --project-name "$NAME" --platforms=android,ios .

# flutter create adds a sample widget test that targets a counter app.
if grep -q "Counter increments smoke test" test/widget_test.dart 2>/dev/null; then
  rm test/widget_test.dart
  echo "▶ Removed the generated counter test."
fi

GRADLE="android/app/build.gradle.kts"
if [ ! -f "$GRADLE" ]; then
  echo "✖ $GRADLE not found — add release signing manually (see CI_CD.md)." >&2
  exit 1
fi

if grep -q "keystoreProperties" "$GRADLE"; then
  echo "▶ Android signing already configured."
else
  echo "▶ Configuring Android release signing…"
  python3 - "$GRADLE" <<'PY'
import re, sys
path = sys.argv[1]
src = open(path).read()

header = '''import java.io.FileInputStream
import java.util.Properties

'''
loader = '''
// Release signing: values come from android/key.properties (never committed).
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
'''
signing = '''    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

'''
release_line = re.compile(r'signingConfig\s*=\s*signingConfigs\.getByName\("debug"\)')

if 'plugins {' not in src or 'buildTypes {' not in src or not release_line.search(src):
    sys.exit("Unexpected build.gradle.kts layout — configure signing manually (see CI_CD.md).")

src = header + src
end_plugins = src.index('}', src.index('plugins {')) + 1
src = src[:end_plugins] + '\n' + loader + src[end_plugins:]
src = src.replace('    buildTypes {', signing + '    buildTypes {', 1)
src = release_line.sub(
    'signingConfig = if (keystorePropertiesFile.exists()) '
    'signingConfigs.getByName("release") else signingConfigs.getByName("debug")',
    src,
    count=1,
)
open(path, 'w').write(src)
PY
fi

echo "▶ Fetching packages…"
flutter pub get

cat <<'MSG'

✔ Platforms ready. Next steps:
  1. Export the Figma images listed in FIGMA_ANALYSIS.md §6 into assets/images/.
  2. iOS signing (once): open ios/Runner.xcworkspace in Xcode → Runner → Signing &
     Capabilities → Release: untick "Automatically manage signing", pick your team and
     App Store profile. Commit the change.
  3. Commit android/ and ios/ so CI can build them.
MSG
