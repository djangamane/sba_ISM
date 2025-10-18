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

# Generate .env file for build-time assets (values may be empty if not provided).
cat <<EOF > .env
SUPABASE_URL=${SUPABASE_URL:-}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY:-}
API_BASE_URL=${API_BASE_URL:-}
STRIPE_PUBLISHABLE_KEY=${STRIPE_PUBLISHABLE_KEY:-}
EOF

flutter pub get
flutter build web --release \
  --dart-define=SUPABASE_URL="${SUPABASE_URL:-}" \
  --dart-define=SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}" \
  --dart-define=API_BASE_URL="${API_BASE_URL:-}" \
  --dart-define=STRIPE_PUBLISHABLE_KEY="${STRIPE_PUBLISHABLE_KEY:-}"
