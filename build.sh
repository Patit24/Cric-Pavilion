#!/bin/bash
set -e

echo "=== CricPavilion Flutter Web Build for Vercel ==="

# 1. Download Flutter stable if not already present
if [ ! -d "$HOME/flutter" ] && [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK (stable channel)..."
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
fi

if [ -d "$HOME/flutter/bin" ]; then
  export PATH="$PATH:$HOME/flutter/bin"
elif [ -d "flutter/bin" ]; then
  export PATH="$PATH:`pwd`/flutter/bin"
fi

echo "=== Flutter Environment ==="
flutter --version
flutter config --no-analytics

echo "=== Fetching Dependencies ==="
flutter pub get

echo "=== Building Web App for Release ==="
flutter build web --release

echo "=== Flutter Web Build Complete! Files in build/web ==="
