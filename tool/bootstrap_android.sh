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

MANIFEST="$ROOT/android/app/src/main/AndroidManifest.xml"
ICON_DIR="$ROOT/android/app/src/main/res/drawable"
ICON="$ICON_DIR/ic_launcher_chatnu.xml"
mkdir -p "$ICON_DIR"

cat > "$ICON" <<'XML'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp"
    android:height="108dp"
    android:viewportWidth="48"
    android:viewportHeight="48">
    <path
        android:fillColor="#5B7CFF"
        android:pathData="M24,2C11.85,2 2,10.73 2,21.5c0,6.15 3.2,11.64 8.21,15.21L8,46l10.05,-5.14c1.91,0.42 3.9,0.64 5.95,0.64 12.15,0 22,-8.73 22,-20S36.15,2 24,2z" />
    <path
        android:fillColor="#FFFFFF"
        android:pathData="M15,16h18c1.66,0 3,1.34 3,3v9c0,1.66 -1.34,3 -3,3H15c-1.66,0 -3,-1.34 -3,-3v-9c0,-1.66 1.34,-3 3,-3z" />
    <path
        android:fillColor="#5B7CFF"
        android:pathData="M17,21h14v2H17zM17,26h10v2H17z" />
</vector>
XML

python3 - "$MANIFEST" <<'PY'
from pathlib import Path
import sys

manifest = Path(sys.argv[1])
text = manifest.read_text()
text = text.replace('android:label="chatnu"', 'android:label="ChatNU"')
text = text.replace(
    'android:icon="@mipmap/ic_launcher"',
    'android:icon="@drawable/ic_launcher_chatnu"\n        android:roundIcon="@drawable/ic_launcher_chatnu"',
)
manifest.write_text(text)
PY

flutter pub get
