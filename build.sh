#!/bin/bash

set -e  # Останавливаться при ошибках

echo "🚀 Starting iOS IPA build without signing..."

# Get SDK info
SDK_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
echo "📱 iOS SDK path: $SDK_PATH"

# Clean previous builds
rm -rf Payload
rm -f ClickerApp
rm -f ClickerApp.ipa

# Create folder structure
mkdir -p Payload/ClickerApp.app

echo "🔨 Compiling Swift code..."
# Compile Swift code
xcrun swiftc ClickerApp.swift \
  -sdk "$SDK_PATH" \
  -target arm64-apple-ios17.0 \
  -o ClickerApp \
  -framework UIKit \
  -framework Foundation \
  -L "$SDK_PATH/usr/lib" \
  -I "$SDK_PATH/usr/include" \
  -Xlinker -dead_strip

# Check if binary was created
if [ ! -f "ClickerApp" ]; then
    echo "❌ Error: binary not created"
    exit 1
fi

echo "✅ Binary compiled successfully"
echo "📦 Copying binary..."
cp ClickerApp Payload/ClickerApp.app/
chmod +x Payload/ClickerApp.app/ClickerApp

echo "📝 Creating valid Info.plist..."
cat > Payload/ClickerApp.app/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ClickerApp</string>
    <key>CFBundleIdentifier</key>
    <string>com.yourcompany.FlashlightControl</string>
    <key>CFBundleName</key>
    <string>Flashlight Control</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>MinimumOSVersion</key>
    <string>11.0</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
    <key>NSCameraUsageDescription</key>
    <string>Приложению нужен доступ к камере для управления фонариком</string>
</dict>
</plist>
EOF


echo "🖼️ Creating PkgInfo..."
echo "APPL????" > Payload/ClickerApp.app/PkgInfo

echo "📦 Creating IPA..."
cd Payload
echo "Folder contents before creating IPA:"
ls -la ClickerApp.app/
zip -qr ../ClickerApp.ipa .
cd ..

echo "✅ Checking IPA..."
if [ ! -f "ClickerApp.ipa" ]; then
    echo "❌ Error: IPA not created"
    exit 1
fi

IPA_SIZE=$(du -h ClickerApp.ipa | cut -f1)
echo "📊 IPA size: $IPA_SIZE"

echo "📁 IPA contents:"
unzip -l ClickerApp.ipa

# Cleanup
rm -rf Payload
rm -f ClickerApp

echo "🎉 Build completed successfully!"
echo "📦 File: ClickerApp.ipa ($IPA_SIZE)"
