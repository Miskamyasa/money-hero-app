#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SWIFT_DIR="$ROOT_DIR/swift"
SCREENSHOT_DIR="$ROOT_DIR/screenshots"

DEFAULT_DEVICE_ID="6DCA6009-D5E2-439B-818E-7BB575FB5D37"
DEVICE_ID="${DEVICE_ID:-$DEFAULT_DEVICE_ID}"
DERIVED_DATA="${DERIVED_DATA:-/tmp/MoneyHeroRunDerivedData}"
BUILD_PRODUCTS_DIR="$DERIVED_DATA/Build/Products/Debug-iphonesimulator"
BUILD_INTERMEDIATES_DIR="$DERIVED_DATA/Build/Intermediates.noindex"
MODULE_CACHE_DIR="$DERIVED_DATA/ModuleCache.noindex"
SCREENSHOT_PATH="${SCREENSHOT_PATH:-$SCREENSHOT_DIR/dashboard-after-refactor.png}"
BUNDLE_ID="${BUNDLE_ID:-app.moneyhero.mobile}"

mkdir -p "$SCREENSHOT_DIR"

echo "Building MoneyHero for simulator $DEVICE_ID"
rm -rf "$DERIVED_DATA"
xcodebuild \
  -project "$SWIFT_DIR/MoneyHero.xcodeproj" \
  -scheme MoneyHero \
  -configuration Debug \
  -sdk iphonesimulator \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  CLANG_MODULE_CACHE_PATH="$MODULE_CACHE_DIR" \
  ONLY_ACTIVE_ARCH=YES \
  CONFIGURATION_BUILD_DIR="$BUILD_PRODUCTS_DIR" \
  OBJROOT="$BUILD_INTERMEDIATES_DIR" \
  build

APP_PATH="$BUILD_PRODUCTS_DIR/MoneyHero.app"

echo "Installing and launching $BUNDLE_ID"
xcrun simctl boot "$DEVICE_ID" >/dev/null 2>&1 || true
xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl uninstall "$DEVICE_ID" "$BUNDLE_ID" >/dev/null 2>&1 || true
xcrun simctl install "$DEVICE_ID" "$APP_PATH"
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"

echo "Waiting for dashboard to settle"
sleep "${SCREENSHOT_DELAY_SECONDS:-5}"

echo "Capturing screenshot: $SCREENSHOT_PATH"
xcrun simctl io "$DEVICE_ID" screenshot "$SCREENSHOT_PATH"
open "$SCREENSHOT_PATH"
