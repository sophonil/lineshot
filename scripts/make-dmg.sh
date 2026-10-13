#!/bin/bash
# Build a minimal Lineshot disk image; signing/notarization are separate steps.
set -euo pipefail
cd "$(dirname "$0")/.."
scripts/build-app.sh release
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' build/Lineshot.app/Contents/Info.plist)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cp -R build/Lineshot.app "$WORK/"
ln -s /Applications "$WORK/Applications"
hdiutil create -ov -srcfolder "$WORK" -volname Lineshot -format UDZO "build/Lineshot-$VERSION.dmg"
echo "Built build/Lineshot-$VERSION.dmg (not notarized)"
