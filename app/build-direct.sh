#!/usr/bin/env bash
#
# Build the DIRECT (outside-the-App-Store) MenuFC: Developer ID signed + notarized,
# WITH the "Buy me a coffee" link (compiled in via the DIRECT_BUILD flag). Produces a
# ready-to-distribute .dmg.
#
# Prereqs (one-time):
#   • Developer ID Application cert in your keychain (you have it).
#   • A notarization keychain profile. Create it once:
#       xcrun notarytool store-credentials "MenuFC" \
#         --apple-id "you@example.com" --team-id "39PB68QUZJ" \
#         --password "APP-SPECIFIC-PASSWORD"     # appleid.apple.com → Sign-In & Security → App-Specific Passwords
#
# Usage:
#   ./build-direct.sh                 # uses TEAM_ID=39PB68QUZJ, NOTARY_PROFILE=MenuFC
#
set -euo pipefail
cd "$(dirname "$0")"

: "${TEAM_ID:=39PB68QUZJ}"
: "${NOTARY_PROFILE:=MenuFC}"
APP_NAME="MenuFC"
ARCHIVE="build/MenuFC-direct.xcarchive"
EXPORT_DIR="build/direct-export"
DMG="build/${APP_NAME}.dmg"
TMP_OPTS="build/DirectExportOptions.generated.plist"

echo "▶︎ Generating project…"
xcodegen generate

echo "▶︎ Archiving (Developer ID, DIRECT_BUILD → includes the coffee link)…"
xcodebuild -project MenuFC.xcodeproj -scheme MenuFC -configuration Release \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  SWIFT_ACTIVE_COMPILATION_CONDITIONS="DIRECT_BUILD" \
  archive

echo "▶︎ Exporting Developer ID app…"
mkdir -p build
sed "s/__TEAM_ID__/$TEAM_ID/" DirectExportOptions.plist > "$TMP_OPTS"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$TMP_OPTS"

APP="$EXPORT_DIR/${APP_NAME}.app"
[ -d "$APP" ] || { echo "❌ export failed — $APP not found"; exit 1; }

echo "▶︎ Notarizing the app…"
ZIP="build/${APP_NAME}-notarize.zip"
/usr/bin/ditto -c -k --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$NOTARY_PROFILE" --wait

echo "▶︎ Stapling the notarization ticket to the app…"
xcrun stapler staple "$APP"

echo "▶︎ Building the DMG…"
rm -f "$DMG"
STAGING="build/dmg-staging"
rm -rf "$STAGING"; mkdir -p "$STAGING"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING" -ov -format UDZO "$DMG"

echo
echo "✅ Done → $DMG"
echo "   It contains a Developer-ID-signed, notarized, stapled ${APP_NAME}.app (with the coffee link)."
echo "   Sanity check:  spctl --assess --type execute -vv \"$APP\""
echo "   Publish:       gh release create v1.0-direct \"$DMG\" --title \"MenuFC v1.0 (direct)\" \\"
echo "                    --notes \"Direct download. Drag MenuFC to Applications.\""
