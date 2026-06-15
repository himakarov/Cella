#!/bin/bash
set -e

REPO="himakarov/Cella"
APP="Cella.app"
INSTALL_DIR="/Applications"
TMP="/tmp/Cella.zip"

echo "==> Downloading latest Cella..."
curl -fSL "https://github.com/$REPO/releases/latest/download/Cella.zip" -o "$TMP"

echo "==> Installing to $INSTALL_DIR..."
pkill -x Cella 2>/dev/null || true
rm -rf "$INSTALL_DIR/$APP"
unzip -q "$TMP" -d "$INSTALL_DIR"
rm "$TMP"

echo "==> Removing quarantine flag..."
xattr -cr "$INSTALL_DIR/$APP"

echo "==> Launching Cella..."
open "$INSTALL_DIR/$APP"

echo "Done: Cella installed and launched."
