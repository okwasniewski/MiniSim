#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_FILE="$PROJECT_ROOT/MiniSim.xcodeproj"
DIST_DIR="$PROJECT_ROOT/dist"
DERIVED_DATA_DIR="$DIST_DIR/DerivedData"
STAGING_DIR="$DIST_DIR/dmg-staging"
APP_PATH="$DERIVED_DATA_DIR/Build/Products/Release/MiniSim.app"
DMG_PATH="$DIST_DIR/MiniSim.dmg"

# Reuse an existing Xcode package checkout when available. This avoids an
# unnecessary network clone on machines that have already built MiniSim.
PACKAGE_SOURCE_DIR="${PACKAGE_SOURCE_DIR:-}"
if [[ -z "$PACKAGE_SOURCE_DIR" ]]; then
  PACKAGE_SOURCE_DIR="$(find "$HOME/Library/Developer/Xcode/DerivedData" \
    -maxdepth 3 \
    -type d \
    -path '*/MiniSim-*/SourcePackages' \
    -print \
    -quit 2>/dev/null || true)"
fi

if [[ ! -d "$PROJECT_FILE" ]]; then
  echo "Project not found: $PROJECT_FILE" >&2
  exit 1
fi

echo "Building unsigned Release app for arm64 and x86_64..."
rm -rf "$DERIVED_DATA_DIR" "$STAGING_DIR" "$DMG_PATH"
mkdir -p "$DIST_DIR"

XCODEBUILD_ARGS=(
  -skipPackageUpdates \
  -project "$PROJECT_FILE" \
  -scheme MiniSim \
  -configuration Release \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build
)

if [[ -n "$PACKAGE_SOURCE_DIR" ]]; then
  echo "Reusing Swift package cache: $PACKAGE_SOURCE_DIR"
  XCODEBUILD_ARGS=(
    -clonedSourcePackagesDirPath "$PACKAGE_SOURCE_DIR"
    "${XCODEBUILD_ARGS[@]}"
  )
fi

xcodebuild "${XCODEBUILD_ARGS[@]}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "Build succeeded but MiniSim.app was not found: $APP_PATH" >&2
  exit 1
fi

echo "Preparing DMG contents..."
mkdir -p "$STAGING_DIR"
ditto "$APP_PATH" "$STAGING_DIR/MiniSim.app"
ln -s /Applications "$STAGING_DIR/Applications"

echo "Creating $DMG_PATH..."
hdiutil create \
  -volname "MiniSim" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$DMG_PATH"

echo
echo "DMG created successfully:"
echo "$DMG_PATH"
echo
file "$APP_PATH/Contents/MacOS/MiniSim" "$DMG_PATH"
