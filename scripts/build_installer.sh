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

echo "💿 Creating DMG..."
hdiutil create -volname "${APP_NAME}" -srcfolder "${APP_BUNDLE}" -ov -format UDZO "${DMG_NAME}" || {
    echo "⚠️ DMG creation failed (likely due to sandbox restrictions)."
    echo "📦 Creating ZIP instead..."
    zip -r "${APP_NAME}.zip" "${APP_BUNDLE}"
}

echo "✅ Done!"
