#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="NoSleepToggle"
APP_PATH="$ROOT_DIR/dist/$APP_NAME.app"
DMG_PATH="$ROOT_DIR/release/$APP_NAME.dmg"

# Required:
#   CODESIGN_IDENTITY='Developer ID Application: Your Name (TEAMID)'
#   NOTARY_PROFILE='notary-profile-name'
# Optional:
#   TEAM_ID='TEAMID'

if [[ -z "${CODESIGN_IDENTITY:-}" ]]; then
  echo "Missing CODESIGN_IDENTITY env var."
  exit 1
fi

if [[ -z "${NOTARY_PROFILE:-}" ]]; then
  echo "Missing NOTARY_PROFILE env var."
  exit 1
fi

if ! security find-identity -v -p codesigning | grep -F "$CODESIGN_IDENTITY" >/dev/null; then
  echo "Codesign identity not found in keychain: $CODESIGN_IDENTITY"
  exit 1
fi

"$ROOT_DIR/scripts/create_dmg.sh"

echo "Signing app..."
codesign \
  --force \
  --options runtime \
  --timestamp \
  --sign "$CODESIGN_IDENTITY" \
  "$APP_PATH"

echo "Verifying app signature..."
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo "Rebuilding signed DMG..."
rm -f "$DMG_PATH"
STAGE_DIR="$ROOT_DIR/release/dmg-stage-signed"
rm -rf "$STAGE_DIR"
mkdir -p "$STAGE_DIR"
cp -R "$APP_PATH" "$STAGE_DIR/$APP_NAME.app"
ln -s /Applications "$STAGE_DIR/Applications"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGE_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"
rm -rf "$STAGE_DIR"

echo "Signing DMG..."
codesign \
  --force \
  --timestamp \
  --sign "$CODESIGN_IDENTITY" \
  "$DMG_PATH"

echo "Submitting DMG for notarization..."
xcrun notarytool submit "$DMG_PATH" \
  --keychain-profile "$NOTARY_PROFILE" \
  --wait

echo "Stapling tickets..."
xcrun stapler staple "$APP_PATH"
xcrun stapler staple "$DMG_PATH"

echo "Gatekeeper assessment..."
spctl --assess --type execute --verbose "$APP_PATH"
spctl --assess --type open --context context:primary-signature --verbose "$DMG_PATH"

echo "Done: signed + notarized DMG at $DMG_PATH"
