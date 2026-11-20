#!/usr/bin/env bash
set -e

echo "=== Building RobloxOptimizer.dylib ==="

TARGET="RobloxOptimizer.dylib"
BUILD_DIR="build"

mkdir -p "$BUILD_DIR"

SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path 2>/dev/null || true)
EXTRA_FLAGS=""
if [ -n "$SDK_PATH" ]; then
    EXTRA_FLAGS="-isysroot $SDK_PATH"
fi

xcrun -sdk iphoneos clang \
  -target arm64-apple-ios14.0 \
  -arch arm64 \
  -shared \
  -dynamiclib \
  -fobjc-arc \
  -O2 \
  -Wall \
  -Wextra \
  $EXTRA_FLAGS \
  -install_name @rpath/$TARGET \
  -framework Foundation \
  -framework UIKit \
  -framework Metal \
  -framework QuartzCore \
  -Isrc \
  -o "$BUILD_DIR/$TARGET" \
  src/ROEntry.m \
  src/Config/ROConfig.m \
  src/Hooks/ROMetalHooks.m \
  src/Hooks/ROResolutionHooks.m \
  src/FFlags/ROFastFlags.m \
  src/UI/ROPassThroughWindow.m \
  src/UI/ROFloatingButton.m \
  src/UI/ROMenuViewController.m

if command -v ldid &> /dev/null; then
    ldid -S "$BUILD_DIR/$TARGET"
    echo "Ad-hoc codesign complete with ldid -S."
else
    echo "Notice: ldid not found. Output binary is unsigned."
fi

echo "Build complete: $BUILD_DIR/$TARGET"
