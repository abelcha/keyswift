#!/bin/bash

# Create app bundle directory structure
APP_NAME="KeyShift.app"
APP_DIR="$APP_NAME/Contents"
mkdir -p "$APP_DIR/MacOS"
mkdir -p "$APP_DIR/Resources"

# Copy executable
cp .build/release/KeyShiftApp "$APP_DIR/MacOS/"

# Create Info.plist
cat > "$APP_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>KeyShiftApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.example.KeyShift</string>
    <key>CFBundleName</key>
    <string>KeyShift</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>10.15</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# Make executable
chmod +x "$APP_DIR/MacOS/KeyShiftApp"

echo "Created $APP_NAME bundle"
