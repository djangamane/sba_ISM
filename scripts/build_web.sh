#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.24.1}"
FLUTTER_CHANNEL="${FLUTTER_CHANNEL:-stable}"

echo "Downloading Flutter ${FLUTTER_VERSION}-${FLUTTER_CHANNEL}..."
curl -L "https://storage.googleapis.com/flutter_infra_release/releases/${FLUTTER_CHANNEL}/linux/flutter_linux_${FLUTTER_VERSION}-${FLUTTER_CHANNEL}.tar.xz" \
  --output /tmp/flutter.tar.xz
mkdir -p /tmp/flutter-sdk
tar xf /tmp/flutter.tar.xz -C /tmp/flutter-sdk

export FLUTTER_HOME="/tmp/flutter-sdk/flutter"
export PATH="${FLUTTER_HOME}/bin:${PATH}"

git config --global --add safe.directory "${FLUTTER_HOME}"

flutter config --no-analytics >/dev/null 2>&1 || true
flutter --version

flutter config --enable-web
flutter precache --web

echo "Building Flutter web app..."
cd mobile/spiritual_bible_chat
flutter pub get
flutter build web --release
