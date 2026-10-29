#!/usr/bin/env bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "📱 Desplegando MovieSocialApp en el simulador..."

# Buscar binario compilado más reciente
DERIVED_DIR=$(find ~/Library/Developer/Xcode/DerivedData -name "*MovieSocialApp*" -maxdepth 1 2>/dev/null | head -n 1)
BINARY_PATH="$DERIVED_DIR/Build/Products/Debug-iphonesimulator/MovieSocialApp"

if [ ! -f "$BINARY_PATH" ]; then
    echo "⚠️ Binario no encontrado en $BINARY_PATH, compilando..."
    swift build --target MovieSocialAppRun
fi

APP_DIR="/tmp/MovieSocialApp-iOS.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"

cp "$DIR/Info-iOS.plist" "$APP_DIR/Info.plist"
cp "$BINARY_PATH" "$APP_DIR/MovieSocialApp"
chmod +x "$APP_DIR/MovieSocialApp"

codesign -s - --force "$APP_DIR" >/dev/null 2>&1

echo "🔄 Reiniciando app en simulador..."
xcrun simctl terminate booted com.moviesocial.app 2>/dev/null || true
xcrun simctl install booted "$APP_DIR"
xcrun simctl launch booted com.moviesocial.app

echo "✅ MovieSocialApp desplegada y ejecutándose con éxito en el simulador."
