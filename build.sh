#!/bin/bash

# Создаем структуру папок
mkdir -p Payload/ClickerApp.app

# Компилируем Swift код
echo "🔨 Компилируем Swift код..."
xcrun swiftc ClickerApp.swift \
  -sdk $(xcrun --sdk iphoneos --show-sdk-path) \
  -target arm64-apple-ios15.0 \
  -o ClickerApp \
  -framework UIKit \
  -framework Foundation \
  -L $(xcrun --sdk iphoneos --show-sdk-path)/usr/lib \
  -I $(xcrun --sdk iphoneos --show-sdk-path)/usr/include \
  -Xlinker -dead_strip \
  -Xlinker -export_dynamic \
  -Xlinker -no_deduplicate \
  -Xlinker -objc_abi_version \
  -Xlinker 2

# Копируем бинарник
echo "📦 Копируем бинарник..."
cp ClickerApp Payload/ClickerApp.app/
chmod +x Payload/ClickerApp.app/ClickerApp

# Создаем Info.plist
echo "📝 Создаем Info.plist..."
cat > Payload/ClickerApp.app/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>ClickerApp</string>
    <极>CFBundleIdentifier</key>
    <string>com.example.ClickerApp</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>ClickerApp</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</极>
    <string>1</string>
    <key>LSRequiresIPhoneOS</key>
    <true/>
    <key>UIRequiredDeviceCapabilities</key>
    <array>
        <string>armv7</string>
    </array>
    <key>UISupportedInterfaceOrientations</key>
    <array>
        <string>UIInterfaceOrientationPortrait</string>
    </array>
    <key>MinimumOSVersion</key>
    <string>15.0</string>
</dict>
</plist>
EOF

# Создаем IPA
echo "📦 Создаем IPA..."
zip -qr ClickerApp.ipa Payload/

echo "✅ Готово! IPA создан: ClickerApp.ipa"
echo "📁 Размер: $(du -h ClickerApp.ipa | cut -f1)"

# Очистка
rm -rf Payload
rm -f ClickerApp

echo "🎉 Сборка завершена!"
