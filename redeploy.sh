#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Stopping Cella..."
pkill -f Cella 2>/dev/null || true

git -C "$SCRIPT_DIR" fetch --tags -q 2>/dev/null || true
VERSION="$(git -C "$SCRIPT_DIR" describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo '1.0')"
bash "$SCRIPT_DIR/build.sh" "$VERSION"

echo "==> Deploying to /Applications..."
rm -rf /Applications/Cella.app
cp -R "$SCRIPT_DIR/Cella.app" /Applications/
rm -rf "$SCRIPT_DIR/Cella.app"

echo "==> Launching..."
open /Applications/Cella.app

echo "Готово: Cella обновлена и запущена из /Applications"
