#!/usr/bin/env bash
set -e

echo "Instalando Flutter..."

git clone https://github.com/flutter/flutter.git -b stable --depth 1
export PATH="$PWD/flutter/bin:$PATH"

flutter --version
flutter config --enable-web
flutter pub get
flutter build web --release --dart-define=API_URL=https://sistema-de-gestion-act-bj8j.onrender.com
