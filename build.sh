#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$SCRIPT_DIR/Cella.app"
RESOURCES_SRC="$SCRIPT_DIR/Sources/Cella/Resources/AppIcon.appiconset"

echo "==> Building release..."
cd "$SCRIPT_DIR"
swift build -c release

echo "==> Assembling Cella.app..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp "$SCRIPT_DIR/.build/release/Cella" "$APP/Contents/MacOS/Cella"

cat > "$APP/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Cella</string>
    <key>CFBundleIdentifier</key>
    <string>com.timurmakarov.cella</string>
    <key>CFBundleName</key>
    <string>Cella</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSUIElement</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST

echo "==> Building AppIcon.icns..."
ICONSET_TMP=$(mktemp -d)/AppIcon.iconset
mkdir -p "$ICONSET_TMP"
cp "$RESOURCES_SRC/icon_16.png"   "$ICONSET_TMP/icon_16x16.png"
cp "$RESOURCES_SRC/icon_32.png"   "$ICONSET_TMP/icon_16x16@2x.png"
cp "$RESOURCES_SRC/icon_32.png"   "$ICONSET_TMP/icon_32x32.png"
cp "$RESOURCES_SRC/icon_64.png"   "$ICONSET_TMP/icon_32x32@2x.png"
cp "$RESOURCES_SRC/icon_128.png"  "$ICONSET_TMP/icon_128x128.png"
cp "$RESOURCES_SRC/icon_256.png"  "$ICONSET_TMP/icon_128x128@2x.png"
cp "$RESOURCES_SRC/icon_256.png"  "$ICONSET_TMP/icon_256x256.png"
cp "$RESOURCES_SRC/icon_512.png"  "$ICONSET_TMP/icon_256x256@2x.png"
cp "$RESOURCES_SRC/icon_512.png"  "$ICONSET_TMP/icon_512x512.png"
cp "$RESOURCES_SRC/icon_1024.png" "$ICONSET_TMP/icon_512x512@2x.png"
iconutil -c icns "$ICONSET_TMP" -o "$APP/Contents/Resources/AppIcon.icns"
rm -rf "$(dirname "$ICONSET_TMP")"

echo "==> Signing (ad-hoc)..."
codesign --force --deep --sign - "$APP"

echo ""
echo "Done: $APP"
