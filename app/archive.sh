#!/usr/bin/env bash
#
# Produce an App Store-ready build of MenuFC.
#
# Prereqs:
#   • Xcode + an Apple Developer account (paid program, for App Store distribution).
#   • XcodeGen:  brew install xcodegen
#   • Your 10-character Apple Developer Team ID.
#       TODO: export TEAM_ID="ABCDE12345"   (developer.apple.com → Membership → Team ID)
#
# Usage:
#   TEAM_ID=ABCDE12345 ./archive.sh
#
set -euo pipefail
cd "$(dirname "$0")"

: "${TEAM_ID:?Set TEAM_ID to your Apple Developer Team ID (developer.apple.com → Membership)}"

ARCHIVE="build/MenuFC.xcarchive"
EXPORT_DIR="build/export"
TMP_OPTS="build/ExportOptions.generated.plist"

echo "▶︎ Generating Xcode project…"
xcodegen generate

echo "▶︎ Archiving (Release, Automatic signing, team $TEAM_ID)…"
xcodebuild -project MenuFC.xcodeproj -scheme MenuFC -configuration Release \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM="$TEAM_ID" CODE_SIGN_STYLE=Automatic \
  archive

echo "▶︎ Exporting for the App Store…"
mkdir -p build
sed "s/__TEAM_ID__/$TEAM_ID/" ExportOptions.plist > "$TMP_OPTS"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$TMP_OPTS" \
  -allowProvisioningUpdates

echo
echo "✅ Done. Export is in $EXPORT_DIR"
echo "   Upload it with Xcode → Organizer, or the Transporter app, or:"
echo "     xcrun altool / notarytool  (see Apple docs)"
