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

flutter pub get
