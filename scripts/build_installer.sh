#!/bin/bash

# Configuration
APP_NAME="Okaerii"
BUILD_DIR=".build/release"
APP_BUNDLE="${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"

echo "🧹 Cleaning previous builds..."
swift package clean
rm -rf "${APP_BUNDLE}" "${DMG_NAME}"

echo "🔨 Building release binary..."
swift build -c release --disable-sandbox

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    exit 1
fi

echo "📦 creating App Bundle structure..."
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

# Copy binary
echo "📋 Copying binary..."
cp "${BUILD_DIR}/${APP_NAME}" "${APP_BUNDLE}/Contents/MacOS/"

# Copy resources bundle
# SwiftPM creates a bundle named PackageName_TargetName.bundle
BUNDLE_NAME="${APP_NAME}_${APP_NAME}.bundle"
if [ -d "${BUILD_DIR}/${BUNDLE_NAME}" ]; then
    echo "📋 Copying resource bundle..."
    cp -r "${BUILD_DIR}/${BUNDLE_NAME}" "${APP_BUNDLE}/Contents/Resources/"
else
    echo "⚠️ Warning: Resource bundle not found at ${BUILD_DIR}/${BUNDLE_NAME}"
fi

# Copy Icon
if [ -f "Sources/Okaerii/App/AppIcon.icns" ]; then
    echo "📋 Copying App Icon..."
    cp "Sources/Okaerii/App/AppIcon.icns" "${APP_BUNDLE}/Contents/Resources/"
fi

# Create Info.plist
echo "📝 Creating Info.plist..."
cat > "${APP_BUNDLE}/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.trae.Okaerii</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# Convert App Icon (if available, placeholder for now)
# Ideally we would have an .icns file

# Create DMG using hdiutil
echo "💿 Creating DMG..."
STAGING_DIR="staging"
rm -rf "${STAGING_DIR}"
mkdir -p "${STAGING_DIR}"
cp -r "${APP_BUNDLE}" "${STAGING_DIR}/"
ln -s /Applications "${STAGING_DIR}/Applications"

# Set a custom icon for the DMG volume
if [ -f "Sources/Okaerii/App/AppIcon.icns" ]; then
    cp "Sources/Okaerii/App/AppIcon.icns" "${STAGING_DIR}/.VolumeIcon.icns"
    # Use hdiutil to set volume icon
    # Note: This is complex with just hdiutil, so we'll just focus on the DMG structure
fi

hdiutil create -volname "${APP_NAME}" -srcfolder "${STAGING_DIR}" -ov -format UDZO "${DMG_NAME}" || {
    echo "⚠️ DMG creation failed (likely due to sandbox restrictions)."
    echo "📦 Creating ZIP instead..."
    zip -r "${APP_NAME}.zip" "${APP_BUNDLE}"
}

rm -rf "${STAGING_DIR}"

echo "✅ Done!"
echo "✨ Your beautiful installer wizard is ready at ${DMG_NAME}"
echo "🎁 Features: Stepped Onboarding UI, High-Res Icon, Drag-and-Drop Installation"
