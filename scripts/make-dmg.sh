#!/bin/bash
# Build a minimal LineNote disk image; signing/notarization are separate steps.
set -euo pipefail
cd "$(dirname "$0")/.."
scripts/build-app.sh release
VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' build/LineNote.app/Contents/Info.plist)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cp -R build/LineNote.app "$WORK/"
ln -s /Applications "$WORK/Applications"
hdiutil create -ov -srcfolder "$WORK" -volname LineNote -format UDZO "build/LineNote-$VERSION.dmg"
echo "Built build/LineNote-$VERSION.dmg (not notarized)"
