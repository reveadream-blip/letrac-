#!/usr/bin/env bash
# Build Flutter web sur Cloudflare Pages (Linux ; Flutter n’est pas inclus dans l’image de build).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

SDK_DIR="$ROOT/.flutter-sdk"

if [[ ! -x "$SDK_DIR/bin/flutter" ]]; then
  rm -rf "$SDK_DIR"
  git clone https://github.com/flutter/flutter.git "$SDK_DIR" --branch stable --depth 1
else
  git -C "$SDK_DIR" fetch --depth 1 origin stable || true
  git -C "$SDK_DIR" checkout stable || true
  git -C "$SDK_DIR" pull --depth 1 origin stable || true
fi

export PATH="$PATH:$SDK_DIR/bin"

flutter config --enable-web --no-analytics
flutter precache --web
flutter pub get
flutter build web --release
