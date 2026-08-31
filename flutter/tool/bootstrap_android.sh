#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -d android ]]; then
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  flutter create \
    --platforms=android \
    --org=ir.devnu \
    --project-name=chatnu \
    "$TMP_DIR/chatnu"
  cp -R "$TMP_DIR/chatnu/android" "$ROOT/android"
fi

mkdir -p android/app/src/main/kotlin/ir/devnu/chatnu
cp tool/android/MainActivity.kt android/app/src/main/kotlin/ir/devnu/chatnu/MainActivity.kt
cp tool/android/AndroidManifest.xml android/app/src/main/AndroidManifest.xml

# Keep the Flutter launcher identity pixel-identical to the canonical Android
# app icon. The source assets come from the supplied ChatNU universal icon pack.
NATIVE_RES="$ROOT/../app/src/main/res"
for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  target="android/app/src/main/res/mipmap-$density"
  mkdir -p "$target"
  rm -f "$target"/ic_launcher.* "$target"/ic_launcher_round.*
  cp "$NATIVE_RES/mipmap-$density/ic_launcher.webp" "$target/ic_launcher.webp"
  cp "$NATIVE_RES/mipmap-$density/ic_launcher_round.webp" "$target/ic_launcher_round.webp"
done

for version in mipmap-anydpi-v26 mipmap-anydpi-v33; do
  target="android/app/src/main/res/$version"
  mkdir -p "$target"
  cp "$NATIVE_RES/$version/ic_launcher.xml" "$target/ic_launcher.xml"
  cp "$NATIVE_RES/$version/ic_launcher_round.xml" "$target/ic_launcher_round.xml"
done

mkdir -p android/app/src/main/res/drawable-xxxhdpi
cp "$NATIVE_RES/drawable-xxxhdpi/chatnu_launcher_foreground.webp" \
  android/app/src/main/res/drawable-xxxhdpi/chatnu_launcher_foreground.webp
cp "$NATIVE_RES/drawable-xxxhdpi/chatnu_launcher_monochrome.webp" \
  android/app/src/main/res/drawable-xxxhdpi/chatnu_launcher_monochrome.webp
mkdir -p android/app/src/main/res/values
cp "$NATIVE_RES/values/colors.xml" android/app/src/main/res/values/colors.xml

# Match the production Android application identity and security baseline so a
# release signed with the existing ChatNU key can upgrade in place and retain
# Android Keystore aliases. When signing secrets are absent, local builds keep
# Flutter's debug signing fallback.
if [[ -f android/app/build.gradle.kts ]]; then
  python3 - <<'PY'
from pathlib import Path

path = Path('android/app/build.gradle.kts')
text = path.read_text()
text = text.replace('compileSdk = flutter.compileSdkVersion', 'compileSdk = 37')
text = text.replace('minSdk = flutter.minSdkVersion', 'minSdk = 24')

if 'val chatNuKeystorePath = System.getenv("CHATNU_KEYSTORE_PATH")' not in text:
    marker = '}\n\nandroid {'
    signing_vars = '''}\n\nval chatNuKeystorePath = System.getenv("CHATNU_KEYSTORE_PATH")\nval chatNuKeystorePassword = System.getenv("CHATNU_KEYSTORE_PASSWORD")\nval chatNuKeyAlias = System.getenv("CHATNU_KEY_ALIAS")\nval chatNuKeyPassword = System.getenv("CHATNU_KEY_PASSWORD")\n\nandroid {'''
    if marker not in text:
        raise SystemExit('Could not locate Android Gradle plugins block')
    text = text.replace(marker, signing_vars, 1)

if 'create("chatnuRelease")' not in text:
    marker = '    buildTypes {'
    signing_config = '''    signingConfigs {\n        if (\n            !chatNuKeystorePath.isNullOrBlank() &&\n            !chatNuKeystorePassword.isNullOrBlank() &&\n            !chatNuKeyAlias.isNullOrBlank() &&\n            !chatNuKeyPassword.isNullOrBlank()\n        ) {\n            create("chatnuRelease") {\n                storeFile = file(chatNuKeystorePath)\n                storePassword = chatNuKeystorePassword\n                keyAlias = chatNuKeyAlias\n                keyPassword = chatNuKeyPassword\n            }\n        }\n    }\n\n    buildTypes {'''
    if marker not in text:
        raise SystemExit('Could not locate Android Gradle buildTypes block')
    text = text.replace(marker, signing_config, 1)

text = text.replace(
    'signingConfig = signingConfigs.getByName("debug")',
    'signingConfig = signingConfigs.findByName("chatnuRelease") ?: signingConfigs.getByName("debug")',
)
path.write_text(text)

gradle_properties = Path('android/gradle.properties')
properties = gradle_properties.read_text() if gradle_properties.exists() else ''
setting = 'android.suppressUnsupportedCompileSdk=37'
if setting not in properties.splitlines():
    properties = properties.rstrip() + f'\n{setting}\n'
    gradle_properties.write_text(properties)
PY
fi

flutter pub get
