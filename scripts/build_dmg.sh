#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/dist"
APP_NAME="Awake"
DMG_NAME="${APP_NAME}.dmg"
STAGING_DIR="${BUILD_DIR}/dmg_staging"

# Configure Xcode developer directory if not already set
if [ -z "${DEVELOPER_DIR}" ]; then
    if [ -d "/Applications/Xcode.app/Contents/Developer" ]; then
        export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"
    elif command -v xcode-select >/dev/null 2>&1; then
        export DEVELOPER_DIR="$(xcode-select -p 2>/dev/null || echo "")"
    fi
fi

# Ensure all icons are up to date
if [ -f "${PROJECT_DIR}/scripts/generate_all_icons.sh" ]; then
    "${PROJECT_DIR}/scripts/generate_all_icons.sh"
fi

echo "=== Building Awake (Release configuration) ==="
mkdir -p "${BUILD_DIR}"
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"

xcodebuild -project "${PROJECT_DIR}/awake.xcodeproj" \
           -scheme awake \
           -configuration Release \
           -derivedDataPath "${BUILD_DIR}/DerivedData" \
           -destination 'platform=macOS' \
           build \
           CODE_SIGN_IDENTITY="" \
           CODE_SIGNING_REQUIRED=NO \
           CODE_SIGNING_ALLOWED=NO

APP_BUNDLE="${BUILD_DIR}/DerivedData/Build/Products/Release/${APP_NAME}.app"

if [ ! -d "${APP_BUNDLE}" ]; then
    echo "Error: ${APP_BUNDLE} was not found."
    exit 1
fi

echo "=== Configuring App Icon & Resources ==="
mkdir -p "${APP_BUNDLE}/Contents/Resources"
if [ -f "${PROJECT_DIR}/awake/AppIcon.icns" ]; then
    cp "${PROJECT_DIR}/awake/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/AppIcon.icns"
fi

/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile AppIcon" "${APP_BUNDLE}/Contents/Info.plist" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon" "${APP_BUNDLE}/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Set :CFBundleIconName AppIcon" "${APP_BUNDLE}/Contents/Info.plist" 2>/dev/null || /usr/libexec/PlistBuddy -c "Add :CFBundleIconName string AppIcon" "${APP_BUNDLE}/Contents/Info.plist" 2>/dev/null || true

echo "=== Configuring Info.plist with URL Scheme (awake://) ==="
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes array" "${APP_BUNDLE}/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0 dict" "${APP_BUNDLE}/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLName string com.awake.mac" "${APP_BUNDLE}/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes array" "${APP_BUNDLE}/Contents/Info.plist" 2>/dev/null || true
/usr/libexec/PlistBuddy -c "Add :CFBundleURLTypes:0:CFBundleURLSchemes:0 string awake" "${APP_BUNDLE}/Contents/Info.plist" 2>/dev/null || true

# Register with macOS LaunchServices if available
if [ -f "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister" ]; then
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "${APP_BUNDLE}" 2>/dev/null || true
fi

echo "=== Compiling Universal Awake CLI (arm64 + x86_64) ==="
swiftc -O "${PROJECT_DIR}/awake-cli/main.swift" \
       -target arm64-apple-macos14.0 \
       -framework Foundation -framework IOKit \
       -o "${PROJECT_DIR}/awake-cli/awake_arm64" 2>/dev/null || true

swiftc -O "${PROJECT_DIR}/awake-cli/main.swift" \
       -target x86_64-apple-macos14.0 \
       -framework Foundation -framework IOKit \
       -o "${PROJECT_DIR}/awake-cli/awake_x86_64" 2>/dev/null || true

if [ -f "${PROJECT_DIR}/awake-cli/awake_arm64" ] && [ -f "${PROJECT_DIR}/awake-cli/awake_x86_64" ]; then
    lipo -create -output "${PROJECT_DIR}/awake-cli/awake" \
         "${PROJECT_DIR}/awake-cli/awake_arm64" \
         "${PROJECT_DIR}/awake-cli/awake_x86_64"
    rm -f "${PROJECT_DIR}/awake-cli/awake_arm64" "${PROJECT_DIR}/awake-cli/awake_x86_64"
elif [ -f "${PROJECT_DIR}/awake-cli/awake_arm64" ]; then
    mv "${PROJECT_DIR}/awake-cli/awake_arm64" "${PROJECT_DIR}/awake-cli/awake"
else
    swiftc -O "${PROJECT_DIR}/awake-cli/main.swift" \
           -framework Foundation -framework IOKit \
           -o "${PROJECT_DIR}/awake-cli/awake"
fi

cp "${PROJECT_DIR}/awake-cli/awake" "${APP_BUNDLE}/Contents/Resources/awake"
chmod 755 "${APP_BUNDLE}/Contents/Resources/awake"

echo "=== Packaging DMG with Custom Volume Icon ==="
cp -R "${APP_BUNDLE}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

# Volume Icon for DMG
if [ -f "${PROJECT_DIR}/awake/AppIcon.icns" ]; then
    cp "${PROJECT_DIR}/awake/AppIcon.icns" "${STAGING_DIR}/.VolumeIcon.icns"
    if command -v SetFile >/dev/null 2>&1; then
        SetFile -c icnC "${STAGING_DIR}/.VolumeIcon.icns" 2>/dev/null || true
        SetFile -a C "${STAGING_DIR}" 2>/dev/null || true
    fi
fi

rm -f "${BUILD_DIR}/${DMG_NAME}"
hdiutil create -volname "${APP_NAME}" \
               -srcfolder "${STAGING_DIR}" \
               -ov \
               -format UDZO \
               "${BUILD_DIR}/${DMG_NAME}"

rm -rf "${STAGING_DIR}"

echo "=== Successfully built ${BUILD_DIR}/${DMG_NAME} ==="
ls -lh "${BUILD_DIR}/${DMG_NAME}"
