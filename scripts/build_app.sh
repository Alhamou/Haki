#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="Haki"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DEST_APPLICATIONS="/Applications/$APP_NAME.app"

echo "=== Building $APP_NAME for macOS (Release) ==="
cd "$PROJECT_DIR"

# 1. Compile release binary
echo "Compiling Swift executable..."
swift build -c release

RELEASE_BIN="$(swift build -c release --show-bin-path)/$APP_NAME"

if [ ! -f "$RELEASE_BIN" ]; then
    echo "Error: Binary not found at $RELEASE_BIN"
    exit 1
fi

# 2. Prepare .app bundle
echo "Creating application bundle at $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 3. Copy binary and Info.plist
cp "$RELEASE_BIN" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

if [ -f "$PROJECT_DIR/Resources/AppIcon.icns" ]; then
    cp "$PROJECT_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
fi

# 4. Code sign with entitlements
SIGN_IDENTITY=$(security find-identity -v -p codesigning | grep "Apple Development:" | grep -v "REVOKED" | head -n 1 | sed -E 's/.*"([^"]+)".*/\1/' || true)
if [ -z "$SIGN_IDENTITY" ]; then
    SIGN_IDENTITY="-"
    echo "Signing application bundle with ad-hoc signature..."
else
    echo "Signing application bundle with certificate: $SIGN_IDENTITY..."
fi

ENTITLEMENTS="$PROJECT_DIR/Resources/ArabicDictation.entitlements"
codesign -s "$SIGN_IDENTITY" --force --deep --entitlements "$ENTITLEMENTS" "$APP_BUNDLE"

echo "Application built successfully at: $APP_BUNDLE"

# 5. Install to /Applications
echo "Installing to $DEST_APPLICATIONS..."
rm -rf "$DEST_APPLICATIONS"
cp -R "$APP_BUNDLE" "$DEST_APPLICATIONS"
echo "Successfully installed to $DEST_APPLICATIONS"

echo "=== Build Complete ==="
