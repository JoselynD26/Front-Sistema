#!/usr/bin/env bash
set -euo pipefail

: "${FLUTTER_VERSION:=stable}"

FLUTTER_DIR="$HOME/flutter"

echo "Checking Flutter SDK..."

if [ ! -d "$FLUTTER_DIR" ]; then
  echo "Installing Flutter $FLUTTER_VERSION..."
  git clone -b "$FLUTTER_VERSION" --depth 1 https://github.com/flutter/flutter.git "$FLUTTER_DIR"
else
  echo "Flutter already installed, reusing it"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version

flutter precache --web
flutter pub get
flutter build web --dart-define=API_URL="${API_URL}"
