#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
MASTER_SRC="${SCRIPT_DIR}/clean_awake_icon.png"
APPICONSET_DIR="${ROOT_DIR}/awake/Assets.xcassets/AppIcon.appiconset"
ICONSET_TMP="${SCRIPT_DIR}/Awake.iconset"

echo "=== Generating All macOS App Icon Resolutions ==="

mkdir -p "${APPICONSET_DIR}"
rm -rf "${ICONSET_TMP}"
mkdir -p "${ICONSET_TMP}"

# Generate all 10 standard macOS resolutions
sips -z 16 16     "${MASTER_SRC}" --out "${ICONSET_TMP}/icon_16x16.png"
sips -z 32 32     "${MASTER_SRC}" --out "${ICONSET_TMP}/icon_16x16@2x.png"
sips -z 32 32     "${MASTER_SRC}" --out "${ICONSET_TMP}/icon_32x32.png"
sips -z 64 64     "${MASTER_SRC}" --out "${ICONSET_TMP}/icon_32x32@2x.png"
sips -z 128 128   "${MASTER_SRC}" --out "${ICONSET_TMP}/icon_128x128.png"
sips -z 256 256   "${MASTER_SRC}" --out "${ICONSET_TMP}/icon_128x128@2x.png"
sips -z 256 256   "${MASTER_SRC}" --out "${ICONSET_TMP}/icon_256x256.png"
sips -z 512 512   "${MASTER_SRC}" --out "${ICONSET_TMP}/icon_256x256@2x.png"
sips -z 512 512   "${MASTER_SRC}" --out "${ICONSET_TMP}/icon_512x512.png"
sips -z 1024 1024 "${MASTER_SRC}" --out "${ICONSET_TMP}/icon_512x512@2x.png"

# Copy all resolutions into AppIcon.appiconset
cp "${ICONSET_TMP}"/*.png "${APPICONSET_DIR}/"

# Write Contents.json for Xcode Asset Catalog
cat << 'JSON' > "${APPICONSET_DIR}/Contents.json"
{
  "images" : [
    {
      "size" : "16x16",
      "idiom" : "mac",
      "filename" : "icon_16x16.png",
      "scale" : "1x"
    },
    {
      "size" : "16x16",
      "idiom" : "mac",
      "filename" : "icon_16x16@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "32x32",
      "idiom" : "mac",
      "filename" : "icon_32x32.png",
      "scale" : "1x"
    },
    {
      "size" : "32x32",
      "idiom" : "mac",
      "filename" : "icon_32x32@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "128x128",
      "idiom" : "mac",
      "filename" : "icon_128x128.png",
      "scale" : "1x"
    },
    {
      "size" : "128x128",
      "idiom" : "mac",
      "filename" : "icon_128x128@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "256x256",
      "idiom" : "mac",
      "filename" : "icon_256x256.png",
      "scale" : "1x"
    },
    {
      "size" : "256x256",
      "idiom" : "mac",
      "filename" : "icon_256x256@2x.png",
      "scale" : "2x"
    },
    {
      "size" : "512x512",
      "idiom" : "mac",
      "filename" : "icon_512x512.png",
      "scale" : "1x"
    },
    {
      "size" : "512x512",
      "idiom" : "mac",
      "filename" : "icon_512x512@2x.png",
      "scale" : "2x"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  }
}
JSON

echo "=== Compiling AppIcon.icns via iconutil ==="
iconutil -c icns "${ICONSET_TMP}" -o "${ROOT_DIR}/awake/AppIcon.icns"

rm -rf "${ICONSET_TMP}"

echo "=== Generated AppIcon.appiconset and AppIcon.icns successfully! ==="
ls -lh "${APPICONSET_DIR}"
ls -lh "${ROOT_DIR}/awake/AppIcon.icns"
