#!/bin/bash
set -e

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo "Usage: ./release.sh v1.0.0"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ZIP="/tmp/Cella.zip"

./build.sh "${VERSION#v}"

echo "==> Zipping Cella.app..."
cd "$SCRIPT_DIR"
zip -qr "$ZIP" Cella.app

echo "==> Creating GitHub release $VERSION..."
gh release create "$VERSION" "$ZIP" \
    --title "$VERSION" \
    --notes "See commit history for changes."

rm "$ZIP"
rm -rf "$SCRIPT_DIR/Cella.app"
echo "Done: released $VERSION → https://github.com/himakarov/Cella/releases/tag/$VERSION"
