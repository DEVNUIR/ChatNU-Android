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
mkdir -p android/app/src/main/res/drawable
cp tool/android/MainActivity.kt android/app/src/main/kotlin/ir/devnu/chatnu/MainActivity.kt
cp tool/android/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
cp ../app/src/main/res/drawable/ic_chatnu.xml android/app/src/main/res/drawable/ic_chatnu.xml

# Match the production Android application identity and security baseline so a
# release signed with the existing ChatNU key can upgrade in place and retain
# Android Keystore aliases. When signing secrets are absent, local builds keep
# Flutter's debug signing fallback.
if [[ -f android/app/build.gradle.kts ]]; then
  python3 - <<'PY'
from pathlib import Path

path = Path('android/app/build.gradle.kts')
text = path.read_text()
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
PY
fi

flutter pub get
