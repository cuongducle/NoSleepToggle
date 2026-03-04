#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="NoSleepToggle"
APP_PATH="$ROOT_DIR/dist/$APP_NAME.app"
DMG_DIR="$ROOT_DIR/release"
STAGE_DIR="$DMG_DIR/dmg-stage"
DMG_PATH="$DMG_DIR/$APP_NAME.dmg"

"$ROOT_DIR/scripts/build_app.sh"

rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
cp -R "$APP_PATH" "$STAGE_DIR/$APP_NAME.app"
ln -s /Applications "$STAGE_DIR/Applications"

mkdir -p "$DMG_DIR"
rm -f "$DMG_PATH"

hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGE_DIR"
echo "Created DMG at: $DMG_PATH"
