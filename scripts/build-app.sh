#!/usr/bin/env bash
# Builds build/Tabula.app with the app at Contents/MacOS/Tabula and the CLI at Contents/Helpers/tabula.
set -euo pipefail

CONFIG="${CONFIG:-release}"
# CommandLineTools lacks the SwiftUIMacros plugin (needed for @State on the macOS 27 SDK).
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

swift build -c "$CONFIG"
BIN=$(swift build -c "$CONFIG" --show-bin-path)
APP=build/Tabula.app

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Helpers" "$APP/Contents/Resources"

cp "$BIN/TabulaApp" "$APP/Contents/MacOS/Tabula"
cp "$BIN/tabula" "$APP/Contents/Helpers/tabula"
cp Resources/Info.plist "$APP/Contents/Info.plist"

codesign --force --sign - --timestamp=none "$APP/Contents/Helpers/tabula"
codesign --force --sign - --timestamp=none "$APP"
