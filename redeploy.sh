#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Stopping Cella..."
pkill -f Cella 2>/dev/null || true

bash "$SCRIPT_DIR/build.sh"

echo "==> Deploying to /Applications..."
rm -rf /Applications/Cella.app
cp -R "$SCRIPT_DIR/Cella.app" /Applications/

echo "==> Launching..."
open /Applications/Cella.app

echo "Готово: Cella обновлена и запущена из /Applications"
