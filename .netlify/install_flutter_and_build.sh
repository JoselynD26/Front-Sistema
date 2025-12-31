#!/usr/bin/env bash
set -euo pipefail

: "${FLUTTER_VERSION:=stable}"

echo "Installing Flutter ${FLUTTER_VERSION}..."
git clone -b "${FLUTTER_VERSION}" --depth 1 https://github.com/flutter/flutter.git "$HOME/flutter"
export PATH="$HOME/flutter/bin:$PATH"

flutter --version
flutter precache --web
flutter pub get
flutter build web --release --dart-define=API_URL="${API_URL}"
