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

# Match the production Android application identity and security baseline so a
# release signed with the existing ChatNU key can upgrade in place and retain
# Android Keystore aliases.
if [[ -f android/app/build.gradle.kts ]]; then
  python3 - <<'PY'
from pathlib import Path
path = Path('android/app/build.gradle.kts')
text = path.read_text()
text = text.replace('applicationId = "ir.devnu.chatnu"', 'applicationId = "ir.devnu.chatnu"')
text = text.replace('minSdk = flutter.minSdkVersion', 'minSdk = 24')
path.write_text(text)
PY
fi

flutter pub get
