#!/bin/bash
set -e

echo "=== CricPavilion Web Build for Vercel ==="

# 1. If Flutter is installed, build fresh release
if command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK detected on host."
  flutter --version
  flutter config --no-analytics
  flutter pub get
  flutter build web --release
elif [ -d "$HOME/flutter/bin" ]; then
  export PATH="$PATH:$HOME/flutter/bin"
  flutter --version
  flutter config --no-analytics
  flutter pub get
  flutter build web --release
elif [ -f "build/web/index.html" ] && [ -f "build/web/main.dart.js" ]; then
  echo "Pre-compiled production web assets found in build/web!"
  echo "Using optimized pre-built release for instant deployment."
else
  echo "Cloning Flutter SDK (stable channel)..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
  export PATH="$PATH:$HOME/flutter/bin"
  flutter pub get
  flutter build web --release
fi

echo "=== Ready in build/web! Deployment starting ==="
